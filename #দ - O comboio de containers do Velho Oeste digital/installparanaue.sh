#!/bin/bash
# installparanaue.sh - Instala o arsenal do comboio containerizado (Multi-distro)

echo "Montando o arsenal do comboio containerizado..."
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
        apt-get install -y -q curl docker.io snapd

        echo "Configurando Snap e instalando Postman..."
        systemctl enable --now snapd.socket
        snap install postman  
        ;;
    rhel|centos)
        echo "Atualizando sistema (RHEL/CentOS)..."
        yum update -y -q
        yum install -y -q yum-utils curl device-mapper-persistent-data lvm2
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y -q docker-ce docker-ce-cli containerd.io

        # Instala Postman manualmente
        echo "Instalando Postman manualmente..."
        wget https://dl.pstmn.io/download/latest/linux64 -O postman.tar.gz
        sudo tar -xzf postman.tar.gz -C /opt
        sudo ln -sf /opt/Postman/Postman /usr/bin/postman
        rm -f postman.tar.gz

        # Define o diretório home do usuário que chamou o sudo
        USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)

        # Cria o diretório e o atalho .desktop para o usuário correto
        sudo mkdir -p $USER_HOME/.local/share/applications
        sudo tee $USER_HOME/.local/share/applications/postman.desktop > /dev/null << EOF
[Desktop Entry]
Name=Postman
Exec=/usr/bin/postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;
EOF
        sudo chown $SUDO_USER:$SUDO_USER $USER_HOME/.local/share/applications/postman.desktop
        ;;
    *)
        echo "Distro não suportada: $OS"
        exit 1
        ;;
esac

# Cria estrutura de pastas do comboio
mkdir -p comboio
chmod 777 comboio

echo "Instalando o maquinista (Docker Compose)..."
DOCKER_COMPOSE_VERSION="v2.27.0"
curl -SL "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-linux-x86_64" \
  -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -sf /usr/local/bin/docker-compose /usr/bin/docker-compose

echo "Preparando os vagões do comboio..."
for img in python:3.11-alpine golang:1.21-alpine postgres:15-alpine; do
    docker pull $img
done

echo "Ativando a locomotiva (Docker)..."
systemctl enable --now docker
usermod -aG docker $SUDO_USER 2>/dev/null || true

echo "Configurando os trilhos (permissões)..."
newgrp docker <<EONG
echo "Trilhos preparados - usuário tem acesso ao Docker"
EONG

echo "-------------------------------------------"
echo "Instalação concluída em $OS!"