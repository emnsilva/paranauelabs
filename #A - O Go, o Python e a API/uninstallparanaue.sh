#!/bin/bash
# uninstallparanaue.sh - Remove completamente o arsenal das APIs

echo "Desinstalando paranauês..."
echo "------------------------------------"

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Nao foi possível detectar a distro"
    exit 1
fi

# Remove pacotes conforme a distro
case $OS in
    ubuntu|debian)
        echo "Removendo paranauês (Ubuntu/Debian)..."
        sudo snap remove postman
        sudo apt-get remove -y python3-flask golang-go snapd
        sudo apt-get autoremove -y
        ;;
    
    rhel|centos)
        echo "Removendo paranauês (RHEL/CentOS)..."
        # Remove Postman manualmente
        sudo rm -rf /opt/Postman
        sudo rm -f /usr/bin/postman
        sudo rm -f /usr/local/bin/postman
        
        # Remove .desktop file
        USER_HOME=$(getent passwd $SUDO_USER 2>/dev/null | cut -d: -f6)
        if [ -n "$USER_HOME" ]; then
            sudo rm -f $USER_HOME/.local/share/applications/postman.desktop
        fi
        
        # Remove pacotes Python/Go
        pip3 uninstall -y flask
        sudo yum remove -y golang python3-pip
        ;;
esac

# Remove projeto e configurações Go
echo "Removendo projeto e configurações..."
rm -rf ~/apis
rm -rf /tmp/apis
sudo rm -rf /root/apis

# Limpa cache e arquivos temporários
echo "Limpando cache..."
go clean -modcache 2>/dev/null || true
pip3 cache purge 2>/dev/null || true

echo "------------------------------------"
echo "Desinstalação completa!"
