#!/bin/sh
# bootstrap-tools.sh — kit do lab: bash, git, make, jq, helm, kubeconform, yamllint
# Portátil: Alpine (apk), Debian/Ubuntu (apt), RHEL/Fedora (dnf/yum),
# openSUSE (zypper), Arch (pacman), macOS (brew). POSIX sh — não exige bash.
# Idempotente: pode rodar quantas vezes quiser.

set -eu

# ── 1. Privilégio: root, sudo ou doas ──────────────────────────────
SUDO=""
if [ "$(id -u)" -ne 0 ]; then
  if   command -v sudo >/dev/null 2>&1; then SUDO="sudo"
  elif command -v doas  >/dev/null 2>&1; then SUDO="doas"
  else
    echo "✗ Sem root. Rode 'su -c \"sh scripts/bootstrap-tools.sh\"' ou instale sudo/doas."
    exit 1
  fi
fi
as_root() { if [ -n "$SUDO" ]; then $SUDO "$@"; else "$@"; fi; }

# ── 2. SO, arquitetura e gerenciador de pacotes ────────────────────
OS=$(uname -s | tr '[:upper:]' '[:lower:]')          # linux | darwin
ARCH=$(uname -m)
case "$ARCH" in
  x86_64|amd64)  BINARCH=amd64 ;;
  aarch64|arm64) BINARCH=arm64 ;;
  *) echo "✗ Sem binário pré-compilado para $ARCH"; exit 1 ;;
esac

PKG=""
for pm in apk apt-get dnf yum zypper pacman brew; do
  command -v "$pm" >/dev/null 2>&1 && { PKG="$pm"; break; }
done
[ -n "$PKG" ] || { echo "✗ Gerenciador de pacotes não reconhecido"; exit 1; }
echo "→ $OS · $BINARCH · gerenciador: $PKG"

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}

# ── 3. Pacotes base ────────────────────────────────────────────────
BASE="curl tar git make jq bash"
case "$PKG" in
  apk)     as_root apk add --no-cache $BASE python3 py3-pip ;;
  apt-get) as_root apt-get update -qq && as_root apt-get install -y -qq $BASE python3 python3-pip ;;
  dnf)     as_root dnf install -y -q $BASE python3 python3-pip ;;
  yum)     as_root yum install -y -q $BASE python3 python3-pip ;;
  zypper)  as_root zypper --non-interactive install $BASE python3 python3-pip ;;
  pacman)  as_root pacman -Sy --noconfirm --needed $BASE python python-pip ;;
  brew)    brew install $BASE python ;;
esac

# ── 4. Helm — binário universal, com checksum ──────────────────────
HELM_VERSION="${HELM_VERSION:-$(curl -sL https://get.helm.sh/helm3-latest-version | tr -d '[:space:]')}"
HELM_TGZ="/tmp/helm-${OS}-${BINARCH}.tgz"
curl -sL "https://get.helm.sh/helm-${HELM_VERSION}-${OS}-${BINARCH}.tar.gz"     -o "$HELM_TGZ"
curl -sL "https://get.helm.sh/helm-${HELM_VERSION}-${OS}-${BINARCH}.tar.gz.sha256" -o "${HELM_TGZ}.sha256"
[ "$(sha256_of "$HELM_TGZ")" = "$(cat "${HELM_TGZ}.sha256")" ] || { echo "✗ checksum do helm não bate"; exit 1; }
tar xzf "$HELM_TGZ" -C /tmp
as_root mkdir -p /usr/local/bin
as_root install -m 0755 "/tmp/${OS}-${BINARCH}/helm" /usr/local/bin/helm
echo "✓ helm ${HELM_VERSION}"

# ── 5. kubeconform — binário universal ─────────────────────────────
curl -sL "https://github.com/yannh/kubeconform/releases/latest/download/kubeconform-${OS}-${BINARCH}.tar.gz" | tar xz -C /tmp
as_root install -m 0755 /tmp/kubeconform /usr/local/bin/kubeconform
echo "✓ kubeconform"

# ── 6. yamllint — pacote nativo > pip (com PEP 668 coberto) ────────
if ! command -v yamllint >/dev/null 2>&1; then
  case "$PKG" in
    apk)     as_root apk add --no-cache yamllint 2>/dev/null || true ;;
    apt-get) as_root apt-get install -y -qq yamllint 2>/dev/null || true ;;
    brew)    brew install yamllint 2>/dev/null || true ;;
  esac
fi
if ! command -v yamllint >/dev/null 2>&1; then
  pip3 install yamllint >/dev/null 2>&1 || pip3 install --break-system-packages yamllint
fi
# pip caiu em ~/.local/bin fora do PATH? symlink resolve pra sempre
if [ -x "$HOME/.local/bin/yamllint" ] && ! command -v yamllint >/dev/null 2>&1; then
  as_root ln -sf "$HOME/.local/bin/yamllint" /usr/local/bin/yamllint
fi
command -v yamllint >/dev/null 2>&1 || { echo "✗ yamllint não instalou"; exit 1; }
echo "✓ yamllint"

# ── 7. Kubeconfig seguro (a lição do helm WARNING) ─────────────────
for kc in "$HOME/.kube/config" /home/*/.kube/config; do
  if [ -f "$kc" ]; then chmod 600 "$kc"; echo "✓ $kc → 600"; fi
done

# ── 8. Prova de sanidade ───────────────────────────────────────────
echo ""
echo "── Kit completo? ──"
MISSING=0
for cmd in helm kubeconform yamllint jq make git; do
  if command -v "$cmd" >/dev/null 2>&1; then echo "✓ $cmd"
  else echo "✗ $cmd"; MISSING=1; fi
done
[ "$MISSING" -eq 0 ] && echo "── Tudo verde. make lint te espera. ──" || exit 1

# limpeza
rm -f "$HELM_TGZ" "${HELM_TGZ}.sha256" /tmp/kubeconform
rm -rf "/tmp/${OS}-${BINARCH}"