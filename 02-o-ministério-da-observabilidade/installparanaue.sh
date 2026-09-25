#!/bin/sh
# ============================================================
# installparanaue.sh — k3s + helm
# Suporta: Alpine, Debian, Ubuntu, RHEL, CentOS e derivados
#
# Fases:
#   0. Detecta a distribuição (pkg manager, init, família)
#   1. Prepara a VM (pacotes + cgroups)
#   2. Instala o k3s (server ou agent) via instalador oficial
#   3. Instala o helm (binário estático com checksum)
#   4. Disponibiliza o kubeconfig para o usuário comum
#
# Uso:
#   ssh usuario@VM 'sudo sh -s' < installparanaue.sh
# ============================================================
set -eu

# ------------------------------------------------------------
# BLOCO: CONFIGURAÇÃO
# Parâmetros com padrão, sobrescrevíveis por ambiente. O "env" no comando SSH é necessário porque o sudo descarta variáveis.
# ------------------------------------------------------------
UPGRADE_OS="${UPGRADE_OS:-0}"            # 1 = upgrade do SO antes de tudo
DISABLE_GPG="${DISABLE_GPG:-0}"          # 1 = pula checksum do helm
DISABLE_TRAEFIK="${DISABLE_TRAEFIK:-1}"  # 1 = server sem ingress traefik
REBOOT="${REBOOT:-0}"                    # 1 = reinicia a VM ao final
K3S_ROLE="${K3S_ROLE:-server}"           # server | agent
K3S_SERVER_IP="${K3S_SERVER_IP:-}"       # IP do server (obrigatório se agent)
K3S_TOKEN="${K3S_TOKEN:-}"               # token do cluster (obrigatório se agent)
K3S_EXTRA_ARGS="${K3S_EXTRA_ARGS:-}"     # argumentos extras do k3s
K3S_VERSION="${K3S_VERSION:-v1.31.2+k3s1}"
HELM_VERSION="${HELM_VERSION:-v3.16.1}"
KUBE_USER="${KUBE_USER:-alpine}"                  # usuário que recebe o kubeconfig
K3S_KUBECONFIG_MODE="${K3S_KUBECONFIG_MODE:-644}" # 644: kubeconfig legível pelo usuário comum (sem "permission denied")
WAIT_KUBECONFIG="${WAIT_KUBECONFIG:-120}"
REBOOT_NEEDED=0

log()  { printf '[+] %s\n' "$*"; }
warn() { printf '[!] %s\n' "$*" >&2; }
die()  { printf '[x] %s\n' "$*" >&2; exit 1; }

# ------------------------------------------------------------
# BLOCO: GUARDA DE ROOT
# Instala pacotes e escreve em /etc e /usr/local — precisa de root. Também evita o bug do sudo herdando stdin consumido.
# ------------------------------------------------------------
[ "$(id -u)" -eq 0 ] || die "Precisa ser root: ssh usuario@VM 'sudo sh -s' < installparanaue.sh"

# FASE 1 — DETECÇÃO DO SISTEMA
# ------------------------------------------------------------
# BLOCO: detect_os() — identifica distro, pkg manager e init
# Fonte da verdade: /etc/os-release (padrão em todas as distros
# suportadas). Define três variáveis que guiam o resto:
#   PKG    — apk | apt | dnf | yum
#   INIT   — openrc (Alpine) | systemd (todas as outras)
#   FAMILY — alpine | debian | rhel  (agrupa comportamentos)
# O ID_LIKE cobre derivados não listados explicitamente
# ------------------------------------------------------------
detect_os() {
  if [ -r /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_ID="${ID:-unknown}"
    OS_LIKE="${ID_LIKE:-}"
  else
    die "/etc/os-release não encontrado — distro não suportada"
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
        *) die "Distribuição não suportada: $OS_ID" ;;
      esac ;;
  esac

  # CentOS 7 e anteriores não têm dnf — cai para yum
  if ! command -v dnf >/dev/null 2>&1; then
    if [ "$PKG" = "dnf" ]; then PKG=yum; fi
  fi

  log "Distribuição: $OS_ID (pkg: $PKG · init: $INIT)"
}

# ------------------------------------------------------------
# BLOCO: HELPERS DE PACOTE — a camada de abstração
# Mesma interface (pkg_update/pkg_install/pkg_upgrade) para os quatro gerenciadores. 
# Qualquer fase que precisar de software chama estes helpers e não sabe em qual distro está.
# ------------------------------------------------------------
pkg_update() {
  case "$PKG" in
    apk) apk update ;;
    apt) apt-get update -qq ;;
    dnf) dnf makecache -q >/dev/null 2>&1 || true ;;
    yum) yum makecache -q >/dev/null 2>&1 || true ;;
  esac
}

pkg_install() {
  case "$PKG" in
    apk) apk add --no-cache "$@" ;;
    apt) DEBIAN_FRONTEND=noninteractive apt-get install -y "$@" ;;
    dnf) dnf install -y "$@" ;;
    yum) yum install -y "$@" ;;
  esac
}

pkg_upgrade() {
  case "$PKG" in
    apk) apk upgrade ;;
    apt) DEBIAN_FRONTEND=noninteractive apt-get upgrade -y ;;
    dnf) dnf upgrade -y ;;
    yum) yum upgrade -y ;;
  esac
}

# FASE 2 — PREPARAÇÃO DA VM
# ------------------------------------------------------------
# BLOCO: prepare() — dependências comuns + cgroups por distro
# Os três pacotes (curl, ca-certificates, iptables) existem com
# o MESMO NOME nas três famílias — só o gerenciador muda.
# A divergência real está nos cgroups:
#   - Alpine (OpenRC): serviço "cgroups" monta /sys/fs/cgroup no boot (não existe cgroupfs-mount aqui);
#   kernel às vezes sem cgroup de memória → add_kernel_opts
#   - systemd (Debian/Ubuntu/RHEL/CentOS): o systemd já monta cgroups sozinho;
#   a checagem de memória ainda roda como rede de segurança (algumas VMs mínimas precisam de opts)
# ------------------------------------------------------------
prepare() {
  log "Preparando VM ($OS_ID · papel: $K3S_ROLE)..."
  pkg_update
  if [ "$UPGRADE_OS" = "1" ]; then pkg_upgrade; fi

  pkg_install curl ca-certificates iptables

  if [ "$INIT" = "openrc" ]; then
    rc-update add cgroups sysinit 2>/dev/null || true
    rc-service cgroups start 2>/dev/null || true
  fi

  ensure_memory_cgroup
}

# ------------------------------------------------------------
# BLOCO: ensure_memory_cgroup() — pré-requisito do kubelet
# Checagem universal (funciona nas três famílias):
#   cgroup v2 → /sys/fs/cgroup/cgroup.controllers deve listar "memory"
#   cgroup v1 → deve existir /sys/fs/cgroup/memory
# Faltando, grava os kernel opts e marca REBOOT_NEEDED.
# ------------------------------------------------------------
ensure_memory_cgroup() {
  if [ -f /sys/fs/cgroup/cgroup.controllers ]; then
    if grep -qw memory /sys/fs/cgroup/cgroup.controllers; then return 0; fi
  elif [ -d /sys/fs/cgroup/memory ]; then
    return 0
  fi
  REBOOT_NEEDED=1
  add_kernel_opts "cgroup_enable=cpuset cgroup_memory=1 cgroup_enable=memory"
}

# ------------------------------------------------------------
# BLOCO: add_kernel_opts() — grava opts no bootloader da distro
# Dois caminhos possíveis:
#   Alpine   → extlinux (/etc/update-extlinux.conf) ou grub
#   Demais   → grub (/etc/default/grub), variável
#              GRUB_CMDLINE_LINUX (existe em Debian, Ubuntu,
#              RHEL, CentOS, Rocky, Alma)
# Regeneração da config por distro:
#   Debian/Ubuntu → update-grub
#   RHEL/CentOS   → grub2-mkconfig -o /boot/grub2/grub.cfg
#   Alpine        → update-extlinux ou grub-mkconfig
# O grep prévio garante idempotência (não duplica opts).
# ------------------------------------------------------------
add_kernel_opts() {
  OPTS="$1"

  # --- Alpine: extlinux (boot BIOS padrão do Alpine) ---
  if [ "$FAMILY" = "alpine" ] && [ -f /etc/update-extlinux.conf ] \
     && command -v update-extlinux >/dev/null 2>&1; then
    if ! grep -q 'cgroup_enable=memory' /etc/update-extlinux.conf; then
      log "Adicionando cgroups ao cmdline (extlinux)..."
      sed -i "s/^default_kernel_opts=\"/& $OPTS/" /etc/update-extlinux.conf
      update-extlinux >/dev/null 2>&1 || warn "update-extlinux falhou; revise /etc/update-extlinux.conf"
    fi

  # --- Todas as distros com GRUB (Debian/Ubuntu/RHEL/CentOS/Alpine-UEFI) ---
  elif [ -f /etc/default/grub ]; then
    if ! grep -q 'cgroup_enable=memory' /etc/default/grub; then
      log "Adicionando cgroups ao cmdline (grub)..."
      if grep -q '^GRUB_CMDLINE_LINUX=' /etc/default/grub; then
        sed -i "s/^GRUB_CMDLINE_LINUX=\"/& $OPTS/" /etc/default/grub
      else
        printf 'GRUB_CMDLINE_LINUX="%s"\n' "$OPTS" >> /etc/default/grub
      fi
      if command -v update-grub >/dev/null 2>&1; then
        update-grub >/dev/null 2>&1 || warn "update-grub falhou"
      elif command -v grub2-mkconfig >/dev/null 2>&1; then
        grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1 \
          || warn "grub2-mkconfig falhou; revise a config do GRUB"
      elif command -v grub-mkconfig >/dev/null 2>&1; then
        grub-mkconfig -o /boot/grub/grub.cfg >/dev/null 2>&1 \
          || warn "grub-mkconfig falhou; revise a config do GRUB"
      else
        warn "Nenhum gerador de GRUB encontrado; adicione manualmente: $OPTS"
      fi
    fi

  else
    warn "Bootloader não identificado. Adicione manualmente ao cmdline: $OPTS"
  fi
}

# FASE 3 — INSTALAÇÃO DO K3S
# ------------------------------------------------------------
# BLOCO: install_k3s() — instalador oficial, multi-distro
# O get.k3s.io detecta sozinho systemd vs OpenRC e cria o serviço certo (/etc/init.d/k3s ou unit do systemd) 
# já com enable. O script só monta: ARGS (linha de comando), ENVV (variáveis: versão, modo do kubeconfig, checksum), 
# valida o papel agent (IP+token obrigatórios) e executa.
# A habilitação redundante no final é defensiva: se o instalador mudar, o serviço continua no boot.
# ------------------------------------------------------------
install_k3s() {
  log "Instalando k3s $K3S_VERSION (papel: $K3S_ROLE)..."
  ARGS="$K3S_EXTRA_ARGS"
  if [ "$K3S_ROLE" = "server" ] && [ "$DISABLE_TRAEFIK" = "1" ]; then
    ARGS="$ARGS --disable traefik"
  fi

  ENVV="INSTALL_K3S_VERSION=$K3S_VERSION K3S_KUBECONFIG_MODE=$K3S_KUBECONFIG_MODE"
  if [ "$DISABLE_GPG" != "1" ]; then
    ENVV="$ENVV VERIFY_CHECKSUM=true"
  fi

  if [ "$K3S_ROLE" = "agent" ]; then
    [ -n "$K3S_SERVER_IP" ] || die "K3S_SERVER_IP é obrigatório quando K3S_ROLE=agent"
    [ -n "$K3S_TOKEN" ]     || die "K3S_TOKEN é obrigatório quando K3S_ROLE=agent"
    ENVV="$ENVV K3S_URL=https://$K3S_SERVER_IP:6443 K3S_TOKEN=$K3S_TOKEN"
    ROLE="agent"
  else
    ROLE="server"
  fi

  # shellcheck disable=SC2086
  curl -sfL https://get.k3s.io | env $ENVV sh -s - $ROLE $ARGS

  if [ "$INIT" = "openrc" ]; then
    rc-update add k3s default 2>/dev/null || true
  else
    systemctl enable k3s >/dev/null 2>&1 || true
  fi
}

# FASE 4 — INSTALAÇÃO DO HELM
# ------------------------------------------------------------
# BLOCO: install_helm() — binário estático, zero diferença por distro: o binário é o mesmo em qualquer Linux. 
# Só varia a arquitetura (amd64/arm64). Checksum sha256 respeitando o DISABLE_GPG, extração e limpeza de temporários.
# ------------------------------------------------------------
install_helm() {
  log "Instalando helm $HELM_VERSION..."
  case "$(uname -m)" in
    x86_64)  HARCH=amd64 ;;
    aarch64) HARCH=arm64 ;;
    *) die "Arquitetura não suportada: $(uname -m)" ;;
  esac
  BASE="https://get.helm.sh/helm-$HELM_VERSION-linux-$HARCH"

  curl -sfL "$BASE.tar.gz" -o /tmp/helm.tgz

  if [ "$DISABLE_GPG" != "1" ]; then
    EXPECTED=$(curl -sfL "$BASE.tar.gz.sha256sum" | awk '{print $1}')
    echo "$EXPECTED  /tmp/helm.tgz" | sha256sum -c - >/dev/null 2>&1 \
      || die "Checksum do helm não bateu"
  fi

  tar -xzf /tmp/helm.tgz -C /tmp
  install -m 0755 "/tmp/linux-$HARCH/helm" /usr/local/bin/helm
  rm -rf /tmp/helm.tgz "/tmp/linux-$HARCH"
}

# FASE 5 — KUBECONFIG PARA O USUÁRIO COMUM
# ------------------------------------------------------------
# BLOCO: setup_kubeconfig() — kubectl sem sudo
# Caminhos do k3s são idênticos em todas as distros
# (/etc/rancher/k3s/k3s.yaml), então o bloco é universal.
# Agents não têm kubeconfig local — só o server copia.
# ------------------------------------------------------------
setup_kubeconfig() {
  [ "$K3S_ROLE" = "server" ] || return 0

  log "Aguardando o k3s gerar o kubeconfig (até ${WAIT_KUBECONFIG}s)..."
  i=0
  while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
    i=$((i + 1))
    if [ "$i" -ge "$WAIT_KUBECONFIG" ]; then
      die "Timeout: k3s não gerou o kubeconfig em ${WAIT_KUBECONFIG}s. Verifique o serviço."
    fi
    # se o serviço caiu durante o bootstrap, não adianta esperar
    if [ "$i" -gt 10 ]; then
      if [ "$INIT" = "openrc" ]; then
        rc-service k3s status >/dev/null 2>&1 \
          || die "Serviço k3s parou durante o bootstrap — veja: rc-service k3s status"
      elif [ "$INIT" = "systemd" ]; then
        systemctl is-active --quiet k3s \
          || die "Serviço k3s parou durante o bootstrap — veja: journalctl -u k3s"
      fi
    fi
    sleep 1
  done
  log "kubeconfig gerado (${i}s)."

  if [ -d "/home/$KUBE_USER" ]; then
    mkdir -p "/home/$KUBE_USER/.kube"
    cp /etc/rancher/k3s/k3s.yaml "/home/$KUBE_USER/.kube/config"
    chown -R "$KUBE_USER:$KUBE_USER" "/home/$KUBE_USER/.kube"
    log "kubeconfig disponível em /home/$KUBE_USER/.kube/config"
  fi
}

# FINALIZAÇÃO
# ------------------------------------------------------------
# BLOCO: check_firewall() — pegadinha das distros enterprise
# RHEL/CentOS/Fedora vêm com firewalld ATIVO e o Ubuntu com ufw
# (às vezes ativo) — ambos bloqueiam 6443/tcp (apiserver),
# 8472/udp (flannel) e 10250/tcp (kubelet). O cluster até
# instala, mas nodes agents não conectam. O script não mexe no
# firewall por conta própria — apenas avisa com o comando certo.
# ------------------------------------------------------------
check_firewall() {
  if command -v firewall-cmd >/dev/null 2>&1 \
     && firewall-cmd --state >/dev/null 2>&1; then
    warn "firewalld ATIVO — libere as portas do k3s ou desative (lab):"
    echo "    firewall-cmd --permanent --add-port=6443/tcp --add-port=8472/udp --add-port=10250/tcp && firewall-cmd --reload"
  fi
  if command -v ufw >/dev/null 2>&1 && ufw status 2>/dev/null | grep -qw active; then
    warn "ufw ATIVO — libere as portas do k3s:"
    echo "    ufw allow 6443/tcp && ufw allow 8472/udp && ufw allow 10250/tcp"
  fi
}

# ------------------------------------------------------------
# BLOCO: summary() — mensagens finais e reboot opcional
# ------------------------------------------------------------
summary() {
  echo
  log "Concluído! ($OS_ID · $PKG · $INIT)"
  if [ "$REBOOT_NEEDED" = "1" ] && [ "$REBOOT" != "1" ]; then
    warn "Cgroups de memória só valem após reboot. Reinicie a VM — o k3s sobe sozinho no boot."
  fi
  echo "  Próximos passos (na VM):"
  echo "    kubectl get nodes"
  check_firewall
  if [ "$REBOOT" = "1" ]; then
    log "Reiniciando em 3s (REBOOT=1)..."
    sleep 3
    reboot
  fi
}

# ------------------------------------------------------------
# BLOCO: main() — orquestração
# detect_os é a fase 0: tudo abaixo dela consulta PKG/INIT/
# FAMILY e se adapta sozinho.
# ------------------------------------------------------------
main() {
  detect_os
  prepare
  install_k3s
  install_helm
  setup_kubeconfig
  summary
}

main