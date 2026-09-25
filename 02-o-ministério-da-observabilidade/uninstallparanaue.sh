#!/bin/sh
# ============================================================
# uninstallparanaue.sh — remoção TOTAL do ambiente (zero resíduos)
# Suporta: Alpine, Debian, Ubuntu, RHEL, CentOS e derivados
#
# Remove: k3s (server/agent), helm, kubeconfigs, redes/iptables,
#         serviço cgroups (só Alpine), kernel opts de cgroup,
#         pacotes gravados no manifest (ou fallback por família)
#         e temporários.
#
# Idempotente: pode rodar mais de uma vez sem quebrar.
#
# Uso:
#   ssh usuario@VM 'sudo sh -s' < uninstallparanaue.sh
#
# Variáveis:
#   REMOVE_PACKAGES=1|0|force   política de remoção de pacotes
#   KUBE_USER=...               (padrão: $SUDO_USER, senão "alpine")
#   REBOOT=1                    reinicia ao final se kernel opts mudaram
# ============================================================
set -u   # sem -e de propósito: limpeza é best-effort, um passo que falha não pode abortar os demais

# ------------------------------------------------------------
# BLOCO: CONFIGURAÇÃO
# REMOVE_PACKAGES tem TRÊS estados (diferente do install):
#   1     → padrão; remove pacotes no Alpine, e nas outras
#           famílias SÓ se houver manifest (ver bloco PACOTES)
#   0     → não remove pacote nenhum
#   force → remove a lista conhecida mesmo em Debian/RHEL
# KUBE_USER: o install copiou o kubeconfig para um usuário;
# aqui o padrão inteligente é o usuário que invocou o sudo (SUDO_USER), caindo para "alpine" quando não há (root puro).
# Se o install usou um KUBE_USER específico, passe o mesmo.
# ------------------------------------------------------------
REMOVE_PACKAGES="${REMOVE_PACKAGES:-1}"
KUBE_USER="${KUBE_USER:-${SUDO_USER:-alpine}}"
REBOOT="${REBOOT:-0}"
REBOOT_RECOMMENDED=0

# Lista de pacotes que o install pode ter adicionado. Nomes que não existem na distro atual são ignorados pelo pkg_installed.
PKG_LIST="curl libcurl brotli-libs c-ares libunistring libidn2 \
nghttp2-libs libpsl libmnl libnftnl libxtables iptables \
iptables-openrc ca-certificates"

log()  { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }

# ------------------------------------------------------------
# BLOCO: GUARDA DE ROOT
# ------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || { warn "Precisa ser root: ssh usuario@VM 'sudo sh -s' < uninstallparanaue.sh"; exit 1; }

# FASE 1 — DETECÇÃO DO SISTEMA (idêntica ao install)
# ------------------------------------------------------------
# BLOCO: detect_os() — mesma lógica do installparanaue.sh
# /etc/os-release define OS_ID/OS_LIKE → PKG, INIT, FAMILY.
# O uninstall precisa disso para: parar/remover serviços no init certo (systemd vs OpenRC),
# remover pacotes no pkg manager certo e regenerar o bootloader certo.
# ------------------------------------------------------------
detect_os() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_LIKE="${ID_LIKE:-}"
  else
    warn "/etc/os-release não encontrado — seguindo com limpeza genérica"
    PKG=unknown; INIT=unknown; FAMILY=unknown
    return 0
  fi

  case "$OS_ID" in
    alpine)                            PKG=apk; INIT=openrc;   FAMILY=alpine ;;
    debian|ubuntu)                     PKG=apt; INIT=systemd;  FAMILY=debian ;;
    rhel|centos|rocky|almalinux|ol|fedora)
                                       PKG=dnf; INIT=systemd;  FAMILY=rhel ;;
    *)
      case "$OS_LIKE" in
        *alpine*)         PKG=apk; INIT=openrc;  FAMILY=alpine ;;
        *debian*)         PKG=apt; INIT=systemd; FAMILY=debian ;;
        *fedora*|*rhel*|*centos*)
                          PKG=dnf; INIT=systemd; FAMILY=rhel ;;
        *) warn "Distribuição desconhecida ($OS_ID) — limpeza genérica"
           PKG=unknown; INIT=unknown; FAMILY=unknown ;;
      esac ;;
  esac

  # CentOS 7 e anteriores não têm dnf
  if [ "$PKG" = "dnf" ] && ! command -v dnf >/dev/null 2>&1; then
    PKG=yum
  fi

  log "Distribuição: $OS_ID (pkg: $PKG · init: $INIT)"
}

# ------------------------------------------------------------
# BLOCO: HELPERS DE PACOTE — espelho dos helpers do install
# pkg_installed: checa existência no formato de cada gerenciador
#   (apk info -e | dpkg-query | rpm -q) — evita erro ao tentar
#   remover nome que não existe nesta distro (ex.: iptables-openrc só existe no Alpine)
# pkg_remove: remove o pacote; em apk/dnf/yum as dependências
#   órfãs saem junto automaticamente; no apt, o autoremove do cleanup_orphans() faz esse papel
# ------------------------------------------------------------
pkg_installed() {
  case "$PKG" in
    apk)      apk info -e "$1" >/dev/null 2>&1 ;;
    apt)      dpkg-query -W -f='${Status}' "$1" 2>/dev/null | grep -qx 'install ok installed' ;;
    dnf|yum)  rpm -q "$1" >/dev/null 2>&1 ;;
    *)        return 1 ;;
  esac
}

pkg_remove() {
  case "$PKG" in
    apk) apk del -q "$@" ;;
    apt) DEBIAN_FRONTEND=noninteractive apt-get remove -y -qq "$@" ;;
    dnf) dnf remove -y -q "$@" ;;
    yum) yum remove -y -q "$@" ;;
  esac
}

cleanup_orphans() {
  case "$PKG" in
    apt) apt-get autoremove -y -qq >/dev/null 2>&1 || true ;;
    *)   : ;;  # apk/dnf/yum já removem órfãs junto com o pacote
  esac
}

# FASE 2 — K3S
# ------------------------------------------------------------
# BLOCO: run_official() — uninstall oficial primeiro
# Os scripts k3s-uninstall.sh / k3s-agent-uninstall.sh vivem no MESMO caminho (/usr/local/bin) em qualquer distro 
# e já sabem parar o serviço no init correto, matar processos, desmontar volumes, limpar iptables e apagar binários/dados. 
# Rodar isso primeiro resolve ~95% do trabalho; o resto do script é a "vassoura fina" que pega o que sobrar (e o caminho manual
# completo, caso o script oficial não exista).
# </dev/null: protege contra o script oficial ler stdin alheio.
# ------------------------------------------------------------
run_official() {
  if [ -x /usr/local/bin/k3s-agent-uninstall.sh ]; then
    log "Executando k3s-agent-uninstall.sh (oficial)..."
    /usr/local/bin/k3s-agent-uninstall.sh </dev/null || true
  elif [ -x /usr/local/bin/k3s-uninstall.sh ]; then
    log "Executando k3s-uninstall.sh (oficial)..."
    /usr/local/bin/k3s-uninstall.sh </dev/null || true
  else
    log "Uninstall oficial ausente — partindo para limpeza manual..."
  fi
}

# ------------------------------------------------------------
# BLOCO: remove_services() — o ponto onde as distros divergem
# OpenRC (Alpine): rc-service stop + rc-update del (k3s do
# runlevel default, cgroups do sysinit — ambos adicionados pelo install)
# systemd (Debian/Ubuntu/RHEL/CentOS): stop/disable/reset-failed +daemon-reload. 
# O install NÃO adicionou serviço de cgroups aqui (systemd monta cgroups sozinho), 
# então não há o que desfazer além do k3s.
# ------------------------------------------------------------
remove_services() {
  if [ "$INIT" = "openrc" ]; then
    log "Removendo serviços do OpenRC..."
    rc-service k3s stop           2>/dev/null || true
    rc-update del k3s default     2>/dev/null || true
    rc-update del cgroups sysinit 2>/dev/null || true
  elif [ "$INIT" = "systemd" ]; then
    log "Removendo serviços do systemd..."
    systemctl stop k3s            2>/dev/null || true
    systemctl disable k3s         2>/dev/null || true
    systemctl reset-failed k3s    2>/dev/null || true
    systemctl daemon-reload       2>/dev/null || true
  else
    warn "Init desconhecido — tentando os dois caminhos..."
    rc-service k3s stop 2>/dev/null || true
    systemctl stop k3s  2>/dev/null || true
  fi
}

# ------------------------------------------------------------
# BLOCO: kill_processes() — universal
# Processos podem sobreviver ao stop do serviço (especialmente se o serviço já não existe mais). 
# -f casa a linha de comando inteira, não o nome do processo.
# ------------------------------------------------------------
kill_processes() {
  log "Encerrando processos remanescentes..."
  pkill -f '/usr/local/bin/k3s' 2>/dev/null || true
  pkill -f 'containerd-shim'    2>/dev/null || true
  sleep 1
}

# ------------------------------------------------------------
# BLOCO: unmount_all() — universal
# O kubelet monta volumes (emptyDir, configMaps, secrets) em /var/lib/kubelet/pods. 
# Desmontar ANTES do rm -rf é essencial: apagar um diretório com mountpoints ativos espalha lixo pelo
# disco real. sort -r desmonta os filhos antes dos pais.
# ------------------------------------------------------------
unmount_all() {
  log "Desmontando volumes remanescentes..."
  mount | awk '/kubelet|rancher|cni|flannel|netns|run\/k3s/ {print $3}' \
    | sort -r | while IFS= read -r m; do
      umount "$m" 2>/dev/null || true
    done
}

# ------------------------------------------------------------
# BLOCO: clean_network() — universal
# Regras iptables v4/v6 criadas pelo kube-proxy/CNI (prefixos KUBE-/CNI-/flannel) e interfaces virtuais do flannel. 
# Caminhos e nomes são padrão k3s, idênticos em todas as distros.
# ------------------------------------------------------------
clean_network() {
  log "Limpando regras iptables (KUBE/CNI/flannel)..."
  if command -v iptables-save >/dev/null 2>&1; then
    iptables-save 2>/dev/null | grep -vE 'KUBE-|CNI-|flannel' | iptables-restore 2>/dev/null || true
  fi
  if command -v ip6tables-save >/dev/null 2>&1; then
    ip6tables-save 2>/dev/null | grep -vE 'KUBE-|CNI-|flannel' | ip6tables-restore 2>/dev/null || true
  fi

  log "Removendo interfaces de rede do cluster..."
  for ifc in cni0 flannel.1 flannel-v6.1 flannel-wg flannel-wg-v6 kube-ipvs0 ni; do
    ip link show "$ifc" >/dev/null 2>&1 && ip link del "$ifc" 2>/dev/null || true
  done
}

# ------------------------------------------------------------
# BLOCO: remove_files() — universal (caminhos k3s são fixos)
# Inclui os dois formatos de unit do systemd (k3s.service e o .env de variáveis) além do script openrc — o rm -f 
# ignora o que não existir. Remove também o diretório do manifest.
# ------------------------------------------------------------
remove_files() {
  log "Removendo arquivos, configs e logs..."
  rm -rf /etc/rancher \
         /etc/cni \
         /var/lib/rancher \
         /var/lib/kubelet \
         /var/lib/cni \
         /run/k3s \
         /run/flannel \
         /var/log/containers \
         /var/log/pods \
         /var/log/k3s /var/log/k3s.log \
         "/home/$KUBE_USER/.kube" \
         /root/.kube \
         /var/lib/paranaue \
         /tmp/helm.tgz /tmp/linux-amd64 /tmp/linux-arm64

  rm -f /usr/local/bin/k3s \
        /usr/local/bin/kubectl /usr/local/bin/crictl /usr/local/bin/ctr \
        /usr/local/bin/k3s-killall.sh \
        /usr/local/bin/k3s-uninstall.sh /usr/local/bin/k3s-agent-uninstall.sh \
        /usr/local/bin/helm \
        /etc/init.d/k3s \
        /etc/systemd/system/k3s.service \
        /etc/systemd/system/k3s.service.env
}

# FASE 3 — KERNEL OPTS (somente se o install os adicionou)
# ------------------------------------------------------------
# BLOCO: remove_kernel_opts() — reverso do add_kernel_opts()
# O install SÓ gravou opts quando o cgroup de memória estava ausente — este bloco só age se encontrá-los (grep), senão é
# no-op nas distros que já vinham configuradas.
#   extlinux → Alpine (boot BIOS)
#   grub     → todas as demais (no Alpine só em UEFI); o sed
#              cobre GRUB_CMDLINE_LINUX e _DEFAULT de uma vez
# Regeneração por família: update-grub (Debian/Ubuntu), grub2-mkconfig (RHEL/CentOS), grub-mkconfig (demais).
# Mudou cmdline ⇒ precisa reboot ⇒ REBOOT_RECOMMENDED.
# ------------------------------------------------------------
remove_kernel_opts() {
  if [ -f /etc/update-extlinux.conf ] && grep -q 'cgroup_enable=memory' /etc/update-extlinux.conf; then
    log "Removendo cgroup opts do cmdline (extlinux)..."
    sed -i 's/ cgroup_enable=cpuset//g; s/ cgroup_memory=1//g; s/ cgroup_enable=memory//g' \
      /etc/update-extlinux.conf
    update-extlinux >/dev/null 2>&1 || warn "update-extlinux falhou; revise o arquivo"
    REBOOT_RECOMMENDED=1
  fi

  if [ -f /etc/default/grub ] && grep -q 'cgroup_enable=memory' /etc/default/grub; then
    log "Removendo cgroup opts do cmdline (grub)..."
    sed -i 's/ cgroup_enable=cpuset//g; s/ cgroup_memory=1//g; s/ cgroup_enable=memory//g' \
      /etc/default/grub
    if command -v update-grub >/dev/null 2>&1; then
      update-grub >/dev/null 2>&1 || warn "update-grub falhou"
    elif command -v grub2-mkconfig >/dev/null 2>&1; then
      grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1 || warn "grub2-mkconfig falhou"
    elif command -v grub-mkconfig >/dev/null 2>&1; then
      grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 || warn "grub-mkconfig falhou"
    else
      warn "Nenhum gerador de GRUB encontrado; revise /etc/default/grub manualmente"
    fi
    REBOOT_RECOMMENDED=1
  fi
}

# FASE 4 — PACOTES
# ------------------------------------------------------------
# BLOCO: remove_packages() — política por evidência
# 1) MANIFEST (/var/lib/paranaue/packages.txt): se o install gravou exatamente o que instalou, 
# removemos ISSO — a única forma 100% segura de desfazer sem afetar pacotes pré-existentes do sistema base.
# 2) SEM manifest (install antigo):
#    - Alpine: remove a lista conhecida — a base mínima do Alpine quase certamente não tinha curl/iptables, 
#    então foi o install que os trouxe (comportamento original)
#    - Debian/RHEL: curl, iptables e ca-certificates costumam vir no sistema base; 
#    removê-los quebraria o sistema. Por padrão MANTER com aviso. REMOVE_PACKAGES=force
#    sobrepõe (uso consciente, ex.: VM descartável).
# ------------------------------------------------------------
remove_packages() {
  MANIFEST=/var/lib/paranaue/packages.txt

  if [ -f "$MANIFEST" ]; then
    log "Removendo pacotes conforme manifest..."
    sort -u "$MANIFEST" | while IFS= read -r p; do
      if pkg_installed "$p"; then
        pkg_remove "$p" >/dev/null 2>&1 || warn "não foi possível remover $p"
      fi
    done
    cleanup_orphans
    rm -rf /var/lib/paranaue
    return 0
  fi

  if [ "$REMOVE_PACKAGES" = "0" ]; then
    log "REMOVE_PACKAGES=0 — pacotes mantidos."
    return 0
  fi

  if [ "$FAMILY" = "alpine" ] || [ "$REMOVE_PACKAGES" = "force" ]; then
    if [ "$FAMILY" != "alpine" ]; then
      warn "REMOVE_PACKAGES=force em $OS_ID — pacotes do sistema base podem ser afetados!"
    fi
    log "Removendo pacotes instalados pelo install..."
    for p in $PKG_LIST; do
      if pkg_installed "$p"; then
        pkg_remove "$p" >/dev/null 2>&1 || warn "não foi possível remover $p (dependência de outro?)"
      fi
    done
    cleanup_orphans
  else
    warn "$OS_ID normalmente já traz curl/iptables/ca-certificates no base —"
    warn "pacotes mantidos. Para remover mesmo assim: REMOVE_PACKAGES=force"
  fi
}

# FASE 5 — VERIFICAÇÃO FINAL
# ------------------------------------------------------------
# BLOCO: verify() — varredura de resíduos por categoria
# Binários/diretórios/processos/regras de rede: universal.
# Runlevels (OpenRC) e unit files (systemd): checados só no init correspondente. 
# ✅ só aparece se TUDO estiver limpo.
# ------------------------------------------------------------
verify() {
  echo
  log "Verificação final de resíduos:"
  RESIDUE=0

  for f in /usr/local/bin/k3s /usr/local/bin/kubectl /usr/local/bin/crictl \
           /usr/local/bin/ctr /usr/local/bin/helm /etc/init.d/k3s \
           /etc/systemd/system/k3s.service /etc/systemd/system/k3s.service.env \
           /usr/local/bin/k3s-killall.sh /usr/local/bin/k3s-uninstall.sh \
           /usr/local/bin/k3s-agent-uninstall.sh; do
    [ -e "$f" ] && { echo "  ⚠ $f"; RESIDUE=1; }
  done

  for d in /etc/rancher /etc/cni /var/lib/rancher /var/lib/kubelet /var/lib/cni \
           /run/k3s /run/flannel /var/log/containers /var/log/pods \
           /root/.kube "/home/$KUBE_USER/.kube"; do
    [ -e "$d" ] && { echo "  ⚠ $d"; RESIDUE=1; }
  done

  if ps aux 2>/dev/null | grep -E '[k]3s|[c]ontainerd-shim' >/dev/null; then
    echo "  ⚠ processos k3s/containerd ainda rodando"; RESIDUE=1
  fi

  for ifc in cni0 flannel.1 flannel-v6.1 flannel-wg flannel-wg-v6 kube-ipvs0; do
    ip link show "$ifc" >/dev/null 2>&1 && { echo "  ⚠ interface $ifc"; RESIDUE=1; }
  done

  if command -v iptables-save >/dev/null 2>&1 \
     && iptables-save 2>/dev/null | grep -qE 'KUBE-|CNI-|flannel'; then
    echo "  ⚠ regras iptables remanescentes"; RESIDUE=1
  fi

  if [ "$INIT" = "openrc" ]; then
    rc-update show default 2>/dev/null | grep -q k3s \
      && { echo "  ⚠ k3s ainda no runlevel default"; RESIDUE=1; }
    rc-update show sysinit 2>/dev/null | grep -q cgroups \
      && { echo "  ⚠ cgroups ainda no runlevel sysinit"; RESIDUE=1; }
  elif [ "$INIT" = "systemd" ]; then
    systemctl list-unit-files 2>/dev/null | grep -q '^k3s\.service' \
      && { echo "  ⚠ unit k3s.service ainda registrada"; RESIDUE=1; }
    systemctl is-active --quiet k3s 2>/dev/null \
      && { echo "  ⚠ serviço k3s ainda ativo"; RESIDUE=1; }
  fi

  [ "$RESIDUE" = "0" ] && echo "  ✅ Nenhum resíduo — sistema limpo."
  return 0
}

# ------------------------------------------------------------
# BLOCO: summary() — encerramento e reboot opcional
# ------------------------------------------------------------
summary() {
  echo
  log "Desinstalação concluída."
  if [ "$REBOOT_RECOMMENDED" = "1" ] && [ "$REBOOT" != "1" ]; then
    warn "Kernel opts foram alterados — reinicie a VM para restaurar o cmdline original."
  fi
  warn "Único vestígio inevitável: histórico de logs (syslog/journald)."
  if [ "$REBOOT" = "1" ]; then
    log "Reiniciando em 3s (REBOOT=1)..."
    sleep 3
    reboot
  fi
}

# ------------------------------------------------------------
# BLOCO: main() — orquestração (ordem importa: serviços e processos primeiro, depois mounts, 
# rede, arquivos e, por último, pacotes — nunca o contrário)
# ------------------------------------------------------------
main() {
  detect_os
  run_official
  remove_services
  kill_processes
  unmount_all
  clean_network
  remove_files
  remove_kernel_opts
  remove_packages
  verify
  summary
}

main