#!/bin/bash
# installparanaue.sh - Instala o arsenal completo para o duelo das APIs (Multi-distro)

# Sai imediatamente se um comando falhar
set -e

# --- Funções Auxiliares ---

install_postman_manual() {
    echo "Instalando Postman manualmente..."
    local POSTMAN_URL="https://dl-agent.pstmn.io/download/latest/linux"
    curl -L "$POSTMAN_URL" -o postman.tar.gz
    sudo tar -xzf postman.tar.gz -C /opt
    sudo ln -sf /opt/Postman/Postman /usr/bin/postman
    rm postman.tar.gz

    mkdir -p ~/.local/share/applications
    cat > ~/.local/share/applications/postman.desktop << EOF
[Desktop Entry]
Name=Postman
Exec=/opt/Postman/Postman
Icon=/opt/Postman/app/resources/app/assets/icon.png
Terminal=false
Type=Application
Categories=Development;
EOF
}

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
        sudo apt-get install -y python3-full python3-flask golang-go sqlite3 curl snapd
        
        echo "Configurando Snap..."
        sudo systemctl enable --now snapd.socket
        
        echo "Instalando Postman..."
        sudo snap install postman
        ;;
    
    rhel|centos|fedora)
        echo "Atualizando sistema (RHEL/CentOS/Fedora)..."
        if command -v dnf &> /dev/null; then
            sudo dnf install -y python3-devel python3-flask golang sqlite curl wget
        else
            sudo yum install -y python3-devel python3-flask golang sqlite curl wget epel-release
        fi
        
        install_postman_manual
        ;;
    *)
        echo "Distribuição '$OS' não suportada por este script." >&2
        exit 1
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