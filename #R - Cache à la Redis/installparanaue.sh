#!/bin/bash
echo "Instalando kit de ferramentas..."
echo "------------------------------------"

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Nao foi possível detectar a distro"
    exit 1
fi

# Instala pacotes conforme a distro
echo "Atualizando sistema..."
case $OS in
    ubuntu|debian)
        sudo apt-get update && sudo apt-get upgrade -y -qq
        sudo apt-get install -y -q curl git docker.io
        ;;
    rhel|centos|fedora)
        sudo yum update -y -q
        sudo yum install -y -q curl git docker.io
        ;;
    *)
        echo "Distro nao suportada: $OS"
        exit 1
        ;;
esac

# Instalar Node.js
echo "Instalando Node.js..."
curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash -
sudo apt-get install -y -q nodejs

# Configurar Docker Compose
echo "Configurando o Sistema de Orquestracao..."
DOCKER_COMPOSE_VERSION="v2.27.0"
sudo curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

# Baixar imagens Docker
echo "Baixando Ferramentas..."
for img in postgres:15 redis:7-alpine node:18-alpine; do
    echo "Baixando: $img"
    docker pull $img
done

# Configurar Docker
echo "Ativando Servico Docker..."
sudo systemctl enable --now docker

# Adicionar usuário ao grupo docker
echo "Configurando permissoes..."
CURRENT_USER=${SUDO_USER:-$USER}
sudo usermod -aG docker $CURRENT_USER

# Criar estrutura de diretórios do projeto
echo "Criando estrutura do projeto..."
mkdir -p lab/{cozinha,balcao,garcons,clientes}
chmod 777 lab/{cozinha,balcao,garcons,clientes}

# Verificar instalações
echo -e "\n INFRAESTRUTURA OPERACIONAL:"
echo "    Docker: $(docker --version 2>/dev/null || echo 'N/A')"
echo "    Docker Compose: $(docker-compose --version 2>/dev/null || echo 'N/A')"
echo "    Node.js: $(node --version 2>/dev/null || echo 'N/A')"
echo "    npm: $(npm --version 2>/dev/null || echo 'N/A')"

echo -e "\n Instalacao concluida!"