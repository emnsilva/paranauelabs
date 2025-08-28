#!/bin/bash
# installparanaue.sh - Instala o kit de stress para testes de logs (Multi-distro)

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
case $OS in
    ubuntu|debian)
        echo "Atualizando sistema (Ubuntu/Debian)..."
        sudo apt-get update && sudo apt-get upgrade -y -qq
        sudo apt-get install -y -q stress-ng golang-go htop
        ;;
    rhel|centos|fedora)
        echo "Atualizando sistema (RHEL/CentOS/Fedora)..."
        sudo yum update -y -q  # Update com upgrade implícito no yum
        sudo yum install -y -q stress-ng golang
        ;;
    *)
        echo "Distro nao suportada: $OS"
        exit 1
        ;;
esac

# Prepara ambiente (funciona em qualquer distro)
mkdir -p logs
chmod 777 logs

echo "Instalacao concluida em $OS!"