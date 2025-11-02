#!/bin/bash
# installparanaue.sh - Instala o arsenal completo para o duelo das APIs (Multi-distro)

# Sai imediatamente se um comando falhar
set -e

# --- Início do Script ---

echo "Instalando paranauês..."
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
case $OS in
    ubuntu|debian)
        echo "Instalando paranauês (Ubuntu/Debian)..."
        sudo apt-get update
        sudo apt-get update -qq
        sudo apt-get install -y python3-full python3-flask golang-go sqlite3 curl snapd

        echo "Configurando Snap e instalando Postman..."
        sudo systemctl enable --now snapd.socket
        sudo snap install postman      
        ;;
    
    rhel|centos)
        echo "Atualizando sistema (RHEL/CentOS)..."
        sudo yum install --skip-broken -y python3-devel python3-pip golang sqlite curl wget
        pip3 install flask

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
esac

# Configuração do projeto (comum a todas as distros)
echo "------------------------------------"
echo "Criando diretório do projeto e configurando ambiente Go..."
mkdir -p apis
chmod 777 apis
cd apis

echo "Configurando módulo Go..."
go mod init api-go
go get github.com/gorilla/mux
go get github.com/mattn/go-sqlite3

echo "Instalacao concluida em $OS!"
