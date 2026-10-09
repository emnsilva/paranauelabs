#!/bin/sh
# installparanaue — prepara a MÁQUINA pro lab: docker+compose, node, python,
# deps, clis de api (newman/bru) e ~/roast pro usuário.
# POSIX puro · idempotente · uso: sudo sh installparanaue.sh
set -eu

# PATH à prova de sudo: o secure_path da família RHEL 10 NÃO inclui /usr/local/bin,
# onde o node (tarball) e as clis do npm moram. Sem isto, "npm: command not found"
# com o node instalado. Debian/Ubuntu e alpine (node via apk) não precisavam —
# mas a linha é barata e imuniza as cinco distros de uma vez.
export PATH="/usr/local/bin:/usr/local/sbin:$PATH"

ok()   { printf '\033[32m✓\033[0m %s\n' "$*"; }
info() { printf '\033[1m→\033[0m %s\n' "$*"; }
warn() { printf '\033[33m! %s\033[0m\n' "$*"; }
die()  { printf '\033[31m✗\033[0m %s\n' "$*" >&2; exit 1; }

SUDO=""
[ "$(id -u)" -ne 0 ] && { command -v sudo >/dev/null || die "rode como root ou com sudo"; SUDO="sudo"; }
USER_TARGET="${SUDO_USER:-$(id -un)}"
USER_HOME="$(grep "^${USER_TARGET}:" /etc/passwd | cut -d: -f6)"
LAB_DIR="$USER_HOME/roast"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

. /etc/os-release
case "$ID" in
  ubuntu|debian)                    FAMILY="apt" ;;
  rhel|centos|rockylinux|almalinux) FAMILY="yum" ;;
  alpine)                           FAMILY="apk" ;;
  *) die "SO não suportado: $ID" ;;
esac
ok "distro: $NAME"

# ---- 1 · dependências ----
info "dependências base…"
case "$FAMILY" in
  apt) export DEBIAN_FRONTEND=noninteractive
       $SUDO apt-get update -y
       $SUDO apt-get install -y ca-certificates curl git xz python3 python3-pip ;;
  yum) $SUDO yum install -y ca-certificates curl git xz python3 python3-pip ;;
  apk) $SUDO apk update; $SUDO apk add ca-certificates curl git xz python3 py3-pip ;;
esac

# ---- 2 · docker ----
command -v docker >/dev/null && ok "docker já instalado: $(docker --version)" || {
  info "instalando docker…"
  if [ "$FAMILY" = "apk" ]; then $SUDO apk add docker docker-cli docker-cli-compose
  else curl -fsSL https://get.docker.com -o "$TMP/getdocker.sh"; $SUDO sh "$TMP/getdocker.sh"; fi
}
if [ "$FAMILY" = "apk" ]; then
  $SUDO rc-update add docker default 2>/dev/null || true
  $SUDO rc-service docker start 2>/dev/null || true
  $SUDO addgroup "$USER_TARGET" docker 2>/dev/null || true
else
  $SUDO systemctl enable --now docker
  $SUDO usermod -aG docker "$USER_TARGET" 2>/dev/null || true
fi
i=0; until $SUDO docker info >/dev/null 2>&1; do
  i=$((i+1)); [ $i -gt 15 ] && die "daemon docker não acordou" || sleep 2
done
ok "docker + compose prontos"

# ---- 3 · node (tarball oficial pinado; alpine usa a LTS do apk) ----
if command -v node >/dev/null; then ok "node já instalado: $(node --version)"
else
  info "instalando node…"
  if [ "$FAMILY" = "apk" ]; then $SUDO apk add nodejs npm
  else
    case "$(uname -m)" in
      x86_64)  ARCH="x64" ;;
      aarch64) ARCH="arm64" ;;
      *) die "arquitetura sem tarball node: $(uname -m)" ;;
    esac
    NODE_VERSION="22.14.0"   # LTS pinada — trocar = item Mudança (backlog v2)
    curl -fsSL "https://nodejs.org/dist/v${NODE_VERSION}/node-v${NODE_VERSION}-linux-${ARCH}.tar.xz" -o "$TMP/node.tar.xz"
    $SUDO tar -xJf "$TMP/node.tar.xz" -C /usr/local --strip-components=1
  fi
fi

# ---- 4 · clis de api (newman = runner Postman · bru = runner Bruno) ----
# saída SEMPRE visível: se falhar, o erro real aparece na tela.
# falha aqui não derruba o install — o rastro do uninstall audita bru/newman.
if $SUDO npm install -g --no-fund --no-audit newman @usebruno/cli; then
  ok "newman + bru prontos"
else
  warn "clis de api falharam (erro acima) — o ambiente segue; me traga esse erro"
fi

# ---- 5 · pasta do lab (dono = usuário; sem isso, scp falha com permission denied) ----
 $SUDO mkdir -p "$LAB_DIR"
 $SUDO chown "$USER_TARGET" "$LAB_DIR"
ok "pasta do lab: $LAB_DIR"

# ---- 6 · bancos (exige o compose junto) ----
if [ -f docker-compose.yml ]; then
  info "puxando imagens mongo:7 e postgres:16…"
  $SUDO docker compose pull
  $SUDO docker compose up -d --wait
  $SUDO docker compose ps
  ok "bancos no ar: mongo :27017 · postgres :5433 (roast/roast/roast)"
else
  ok "compose ausente — bancos sobem quando ele chegar: scp docker-compose.yml usuario@vm:$LAB_DIR/"
fi
ok "pronto! node $(node --version) · $(python3 --version)"