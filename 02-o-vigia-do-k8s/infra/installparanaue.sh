#!/bin/bash

. /etc/os-release

# Cria diretório temporário para instalação e exclui ao final
TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

# 1. Instala dependências base em 5 distros Linux
echo "==> Instalando dependências base..."
case $ID in
    ubuntu|debian)
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y ca-certificates curl gnupg jq python3 python3-venv python3-pip git zstd
        ;;
    rhel|centos)
        yum install -y curl gnupg jq python3 python3-pip git zstd
        ;;
    alpine)
        apk update
        apk add curl ca-certificates bash python3 py3-pip git zstd
        ;;
    *)
        echo "SO não suportado: $ID"
        exit 1
        ;;
esac

# 2. Instala o Docker
echo "==> Instalando Docker..."
if [ "$ID" = "alpine" ]; then
    apk add docker docker-cli docker-cli-compose
    rc-update add docker boot 2>/dev/null || true
    rc-service docker start 2>/dev/null || true
else
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi

# 3. Instala kubectl e minikube
echo "==> Instalando kubectl..."
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/

echo "==> Instalando minikube..."
curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
chmod +x minikube-linux-amd64 && mv minikube-linux-amd64 /usr/local/bin/minikube

# 4. Configura ambiente Python
echo "==> Configurando venv..."
rm -rf /vigia
python3 -m venv /vigia
. /vigia/bin/activate
pip install --upgrade pip
pip install kubernetes langchain langchain-community openai requests slack-sdk
deactivate

# 5. Adiciona o usuário no grupo Docker
USER_TARGET="${SUDO_USER:-$USER}"
if [ "$ID" = "alpine" ]; then
    addgroup $USER_TARGET docker 2>/dev/null || true
else
    usermod -aG docker $USER_TARGET 2>/dev/null || true
fi
chown -R $USER_TARGET:$USER_TARGET $VENV_DIR
chmod -R u+w $VENV_DIR

# 6. Resumo da instalação
echo "  Setup concluído!"
echo "  Docker:   $(docker --version 2>/dev/null || echo 'N/A')"
echo "  kubectl:  $(kubectl version --client 2>/dev/null | grep -o 'v[0-9.]*' | head -1 || echo 'N/A')"
echo "  minikube: $(minikube version 2>/dev/null | head -1 || echo 'N/A')"
echo "  Python:   $(python3 --version 2>/dev/null || echo 'N/A')"
echo "  venv:     /opt/vigia/venv"
echo "  Ativar:   source /opt/vigia/venv/bin/activate"
echo "Reiniciando em 10 segundos..."
sleep 10
reboot