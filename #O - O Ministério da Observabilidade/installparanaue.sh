#!/bin/bash
# installparanaue.sh - Instala o kit de observabilidade do Ministério (Multi-distro)

echo "Instalando infraestrutura de vigilância..."
echo "-------------------------------------------"

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Não foi possível detectar a distro"
    exit 1
fi

# Verifica se é root, caso contrário executa com sudo
[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

# Instala pacotes conforme a distro
case $OS in
    ubuntu|debian)
        echo "Atualizando sistema (Ubuntu/Debian)..."
        apt-get update && apt-get upgrade -y -qq
        apt-get install -y -q stress-ng curl docker.io
        ;;
    rhel|centos|fedora)
        echo "Atualizando sistema (RHEL/CentOS/Fedora)..."
        yum update -y -q
        yum install -y -q stress-ng curl docker.io
        ;;
    *)
        echo "Distro não suportada: $OS"
        exit 1
        ;;
esac

# Cria pasta ministerio com permissão de escrita
mkdir -p ministerio
chmod 777 ministerio

echo "Configurando Docker Compose..."
DOCKER_COMPOSE_VERSION="v2.27.0"
curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "Baixando instrumentos de vigilância..."
for img in prom/prometheus nginx:latest postgres:latest alexeiled/stress-ng:latest prom/node-exporter; do
    docker pull $img
done

echo "Ativando serviços..."
systemctl enable --now docker
usermod -aG docker $SUDO_USER 2>/dev/null || true

echo "Aplicando permissões do Ministério..."
newgrp docker <<EONG
echo "Permissões de vigilância ativadas para sessão atual"
EONG

echo "-------------------------------------------"
echo "Instalação concluída em $OS!"
echo ""
echo "INFRAESTRUTURA DE VIGILÂNCIA OPERACIONAL:"
echo "Go: $(go version 2>/dev/null || echo 'N/A')"
echo "Docker: $(docker --version 2>/dev/null || echo 'N/A')"
echo "Docker Compose: $(docker-compose --version 2>/dev/null || echo 'N/A')"
echo ""
echo "O Ministério declara o sistema pronto para coleta de métricas."