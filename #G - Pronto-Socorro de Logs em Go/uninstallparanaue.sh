#!/bin/bash
# uninstallparanaue.sh - Remove o kit de stress e limpa os arquivos

echo "Removendo kit de ferramentas..."
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
        echo "Removendo pacotes (Ubuntu/Debian)..."
        sudo apt-get remove -y stress-ng golang-go htop
        sudo apt-get autoremove -y
        ;;
    rhel|centos|fedora)
        echo "Removendo pacotes (RHEL/CentOS/Fedora)..."
        sudo yum remove -y stress-ng golang
        ;;
    *)
        echo "Distro nao suportada: $OS"
        exit 1
        ;;
esac

# Remove arquivos criados
echo "Removendo arquivos criados..."
if [ -d "logs" ]; then
    rm -rf logs
    echo "Diretorio 'logs' removido"
fi

# Remove o script stress.sh se estiver no diretório atual
if [ -f "stress.sh" ]; then
    rm -f stress.sh
    echo "Arquivo 'stress.sh' removido"
fi

echo "Desinstalacao concluida em $OS!"
echo "Todos os componentes foram removidos"