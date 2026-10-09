#!/bin/sh
# ============================================================================
# uninstallparanaue — reverte TUDO que o installparanaue fez nesta máquina.
# Sem confirmação · idempotente · 100% POSIX (ash/dash/bash) · best-effort.
# Uso: sudo sh uninstallparanaue.sh [--keep-base] [--purge-lab]
#   --keep-base  mantém curl/git/xz/python3/ca-certificates
#   --purge-lab  apaga também a pasta do lab (o script se copia p/ /tmp antes)
# ============================================================================
set -u

KEEP_BASE=0; PURGE_LAB=0
for arg in "$@"; do
  case "$arg" in
    --keep-base) KEEP_BASE=1 ;;
    --purge-lab) PURGE_LAB=1 ;;
    *) printf '\033[31m✗\033[0m flag desconhecida: %s\n' "$arg" >&2; exit 1 ;;
  esac
done

ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
info() { printf '\033[1m→\033[0m %s\n' "$*"; }
warn() { printf '\033[33m! %s\033[0m\n' "$*"; }

# --purge-lab: apagar a pasta que contém este script exige executar de fora
# dela — o script se copia para /tmp e reexecuta; a cópia se remove no final.
if [ "$PURGE_LAB" = 1 ] && [ -f "$0" ] && [ -z "${PARANAUE_COPIED:-}" ]; then
  PARANAUE_LABROOT="$(CDPATH= cd "$(dirname "$0")" && pwd)"
  PARANAUE_SELF="$(mktemp /tmp/uninstallparanaue.XXXXXXXX)"
  cp "$0" "$PARANAUE_SELF"
  export PARANAUE_COPIED=1 PARANAUE_LABROOT PARANAUE_SELF
  exec sh "$PARANAUE_SELF" "$@"
fi

# ---- privilégio ----
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  command -v sudo >/dev/null 2>&1 || { printf '\033[31m✗\033[0m rode como root ou via sudo\n' >&2; exit 1; }
  SUDO="sudo"
fi
USER_TARGET="${SUDO_USER:-$(id -un)}"

# ---- distro ----
. /etc/os-release
case "$ID" in
  ubuntu|debian)                    FAMILY="apt" ;;
  rhel|centos|rockylinux|almalinux) FAMILY="yum" ;;
  alpine)                           FAMILY="apk" ;;
  *)                                 FAMILY="" ;;
esac

# ---- onde está o lab (mesma detecção do instalador) ----
if [ -n "${PARANAUE_LABROOT:-}" ]; then
  LAB_ROOT="$PARANAUE_LABROOT"
elif [ -f "$0" ]; then
  LAB_ROOT="$(CDPATH= cd "$(dirname "$0")" && pwd)"
elif [ -f "$PWD/docker-compose.yml" ]; then
  LAB_ROOT="$PWD"
else
  LAB_ROOT=""
fi

# ---- saneamento do --purge-lab: jamais apagar raiz ou área de usuário ----
if [ "$PURGE_LAB" = 1 ]; then
  USER_HOME="$(grep "^${USER_TARGET}:" /etc/passwd 2>/dev/null | cut -d: -f6)"
  case "$LAB_ROOT" in
    ""|"/"|"/home"|"/root"|"$USER_HOME"|/home/*)
      warn "--purge-lab recusado em '${LAB_ROOT:-?}' (raiz ou home) — apague o lab na mão"
      PURGE_LAB=0 ;;
  esac
fi

# ---- atalho: máquina já limpa? ----
if [ "$PURGE_LAB" = 0 ] && ! command -v docker >/dev/null 2>&1 \
   && ! command -v node >/dev/null 2>&1 && [ ! -e /var/lib/docker ] \
   && [ ! -e /etc/docker ] && [ ! -e /usr/local/bin/node ]; then
  ok "nada do laboratório nesta máquina — já está limpa"
  exit 0
fi

echo
echo "  Removendo: lab (containers/volumes/rede/imagens) · docker + compose"
echo "             (pacotes, serviço, dados, repos, chaves GPG) · grupo docker ·"
echo "             node/npm + caches · ferramentas base"
[ "$PURGE_LAB" = 1 ] && echo "             · pasta do lab: ${LAB_ROOT:-?}"
echo "  Fica: histórico do shell e (sem --purge-lab) a pasta do lab."
echo

# ====================== 1 · lab: containers, volumes, imagens ===============
info "derrubando o laboratório…"

# daemon acordado? a limpeza de containers precisa dele vivo
if command -v docker >/dev/null 2>&1 && ! $SUDO docker info >/dev/null 2>&1; then
  info "acordando o daemon docker…"
  if [ "$FAMILY" = "apk" ]; then
    $SUDO rc-service docker start >/dev/null 2>&1 || true
  else
    $SUDO systemctl start docker >/dev/null 2>&1 || true
  fi
  sleep 3
fi

if command -v docker >/dev/null 2>&1 && $SUDO docker info >/dev/null 2>&1; then
  # caminho feliz: compose.yml em mãos
  if [ -n "$LAB_ROOT" ] && [ -f "$LAB_ROOT/docker-compose.yml" ]; then
    (cd "$LAB_ROOT" && $SUDO docker compose down -v --remove-orphans >/dev/null 2>&1) || true
  fi
  # varredura manual — cobre down falho e o caso sem compose.yml
  NETS=""
  for c in roast-mongo roast-postgres; do
    NETS="$NETS $($SUDO docker inspect -f '{{range $k,$_ := .NetworkSettings.Networks}}{{$k}} {{end}}' "$c" 2>/dev/null || true)"
  done
  $SUDO docker rm -f roast-mongo roast-postgres >/dev/null 2>&1 || true
  for v in $($SUDO docker volume ls -q 2>/dev/null | grep -E '_(mongo_data|pg_data)$' || true); do
    $SUDO docker volume rm -f "$v" >/dev/null 2>&1 || true
  done
  for n in $NETS; do $SUDO docker network rm "$n" >/dev/null 2>&1 || true; done
  $SUDO docker rmi -f mongo:7 postgres:16 >/dev/null 2>&1 || true
  ok "containers, volumes, rede e imagens do lab removidos"
else
  warn "docker indisponível — os dados caem junto com /var/lib/docker"
fi

# ====================== 2 · docker: serviço, pacotes, dados =================
info "removendo o docker…"
if [ "$FAMILY" = "apk" ]; then
  $SUDO rc-update del docker default >/dev/null 2>&1 || true
  $SUDO rc-update del docker boot     >/dev/null 2>&1 || true
  $SUDO rc-service docker stop        >/dev/null 2>&1 || true
else
  $SUDO systemctl disable --now docker.socket docker containerd >/dev/null 2>&1 || true
fi

case "$FAMILY" in
  apt)
    export DEBIAN_FRONTEND=noninteractive
    $SUDO apt-get purge -y docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras \
      >/dev/null 2>&1 || true
    ;;
  yum)
    $SUDO yum remove -y docker-ce docker-ce-cli containerd.io \
      docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras \
      >/dev/null 2>&1 || true
    ;;
  apk)
    $SUDO apk del docker docker-cli docker-cli-compose >/dev/null 2>&1 || true
    ;;
esac

# dados, config e socket — sobrevivem à remoção do pacote
for p in /var/lib/docker /var/lib/containerd /etc/docker /run/docker.sock \
         /var/run/docker.sock /run/docker.pid /var/run/docker.pid \
         /var/log/docker.log; do
  [ -e "$p" ] && { $SUDO rm -rf "$p"; ok "removido: $p"; }
done

# repositório de pacotes e chaves GPG que o get.docker.com deixa para trás
for p in /etc/apt/sources.list.d/docker.list /etc/apt/sources.list.d/docker-ce.list \
         /etc/apt/keyrings/docker.gpg /usr/share/keyrings/docker-archive-keyring.gpg \
         /usr/share/keyrings/docker-ce.gpg /etc/yum.repos.d/docker-ce.repo; do
  [ -e "$p" ] && { $SUDO rm -f "$p"; ok "removido: $p"; }
done
command -v docker >/dev/null 2>&1 || ok "docker removido"

# ====================== 3 · grupo docker ====================================
info "removendo o grupo docker…"
if [ "$USER_TARGET" != "root" ]; then
  case "$FAMILY" in
    apk) $SUDO delgroup "$USER_TARGET" docker >/dev/null 2>&1 || true ;;
    *)   $SUDO gpasswd -d "$USER_TARGET" docker >/dev/null 2>&1 || true ;;
  esac
fi
if grep -q "^docker:" /etc/group 2>/dev/null; then
  $SUDO groupdel docker >/dev/null 2>&1 || $SUDO delgroup docker >/dev/null 2>&1 || true
  ok "grupo docker removido"
fi

# ====================== 4 · node + npm ======================================
info "removendo node e npm…"
if [ "$FAMILY" = "apk" ]; then
  $SUDO apk del nodejs npm >/dev/null 2>&1 || true
else
  # espelho exato do conteúdo do tarball oficial instalado em /usr/local
  for p in /usr/local/bin/node /usr/local/bin/npm /usr/local/bin/npx \
           /usr/local/bin/corepack /usr/local/share/man/man1/node.1 \
           /usr/local/share/systemtap/tapset/node.stp; do
    [ -e "$p" ] && $SUDO rm -f "$p"
  done
  for d in /usr/local/include/node /usr/local/lib/node_modules /usr/local/share/doc/node; do
    [ -e "$d" ] && $SUDO rm -rf "$d"
  done
fi
if command -v node >/dev/null 2>&1; then
  warn "node ainda no PATH — veio de outra fonte (nvm? pacote do SO?), não removi"
else
  ok "node removido"
fi

# caches e configs de runtime (só existem se algo rodou nesta máquina)
 $SUDO rm -rf /root/.npm /root/.docker >/dev/null 2>&1 || true
for h in /home/*/.npm /home/*/.docker /home/*/.cache/pip /root/.cache/pip; do
  [ -e "$h" ] && $SUDO rm -rf "$h"
done

# ====================== 5 · ferramentas base ================================
if [ "$KEEP_BASE" = 1 ]; then
  info "mantendo as ferramentas base (--keep-base)"
else
  info "removendo ferramentas base…"
  case "$FAMILY" in
    apt)
      export DEBIAN_FRONTEND=noninteractive
      $SUDO apt-get purge -y ca-certificates curl git xz-utils \
        python3 python3-venv python3-pip >/dev/null 2>&1 || true
      $SUDO apt-get autoremove --purge -y >/dev/null 2>&1 || true
      ;;
    yum)
      # ca-certificates (TLS do dnf) e python3 (motor do dnf) FICAM — sistema
      $SUDO yum remove -y curl git xz python3-pip >/dev/null 2>&1 || true
      $SUDO yum autoremove -y >/dev/null 2>&1 || true
      ;;
    apk)
      $SUDO apk del ca-certificates curl git xz python3 py3-pip >/dev/null 2>&1 || true
      $SUDO apk autoremove >/dev/null 2>&1 || true
      ;;
  esac
fi

# ====================== 6 · verificação de rastro ===========================
info "verificando rastro…"
RASTRO=""
command -v docker >/dev/null 2>&1 && RASTRO="$RASTRO binário:docker"
command -v node   >/dev/null 2>&1 && RASTRO="$RASTRO binário:node"
for p in /var/lib/docker /var/lib/containerd /etc/docker /run/docker.sock \
         /usr/local/bin/node /usr/local/lib/node_modules \
         /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.gpg \
         /usr/share/keyrings/docker-archive-keyring.gpg \
         /etc/yum.repos.d/docker-ce.repo /var/log/docker.log \
         /root/.docker /root/.npm; do
  [ -e "$p" ] && RASTRO="$RASTRO $p"
done
for h in /home/*/.docker /home/*/.npm; do
  [ -e "$h" ] && RASTRO="$RASTRO $h"
done
grep -q "^docker:" /etc/group 2>/dev/null && RASTRO="$RASTRO grupo:docker"
if [ -n "$RASTRO" ]; then
  warn "rastros que sobraram (remova na mão se quiser zero absoluto):$RASTRO"
else
  ok "nenhum rastro — máquina limpinha, no estado pré-installparanaue"
fi

# ====================== 7 · encerramento ====================================
echo
echo "  ──────────────────────────────────────────────"
# a cópia de si mesmo (modo --purge-lab) se remove por último
[ -n "${PARANAUE_SELF:-}" ] && rm -f "$PARANAUE_SELF"
exit 0