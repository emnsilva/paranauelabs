#!/bin/bash
# uninstallparanaue.sh - Remove completamente o arsenal das APIs

echo "🔫 Desinstalando todo o paranauê..."
echo "------------------------------------"

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Não foi possível detectar a distro"
    exit 1
fi

# --- Remoção dos Pacotes ---
echo "Removendo pacotes instalados..."

case $OS in
    ubuntu|debian)
        sudo apt-get remove -y --purge python3-flask golang-go sqlite3 curl snapd
        sudo apt-get autoremove -y --purge
        ;;
    
    rhel|centos|fedora)
        if command -v dnf &> /dev/null; then
            sudo dnf remove -y python3-flask golang sqlite curl wget
        else
            sudo yum remove -y python3-flask golang sqlite curl wget
        fi
        ;;
esac

# --- Remoção do Postman ---
echo "Removendo Postman..."

# Remove versão Snap (Ubuntu/Debian)
if command -v snap &> /dev/null; then
    sudo snap remove postman 2>/dev/null || true
fi

# Remove versão manual (RHEL/CentOS/Fedora)
sudo rm -rf /opt/Postman 2>/dev/null || true
sudo rm -f /usr/bin/postman 2>/dev/null || true
rm -f ~/.local/share/applications/postman.desktop 2>/dev/null || true

# --- Limpeza dos Projetos ---
echo "Limpando projetos e configurações..."

# Remove diretório do projeto
rm -rf ~/apis 2>/dev/null || true

# Limpa cache do Go
go clean -modcache 2>/dev/null || true
rm -rf ~/go 2>/dev/null || true

# Limpa cache do Python
python3 -m pip cache purge 2>/dev/null || true

# Limpa arquivos temporários
rm -f postman.tar.gz 2>/dev/null || true

# --- Limpeza de Configurações ---
echo "Limpando configurações..."

# Remove variáveis de ambiente (se foram adicionadas)
if [ -f ~/.bashrc ]; then
    sed -i '/GOPATH\|GOROOT/d' ~/.bashrc 2>/dev/null || true
fi

if [ -f ~/.profile ]; then
    sed -i '/GOPATH\|GOROOT/d' ~/.profile 2>/dev/null || true
fi

# --- Finalização ---
echo "------------------------------------"
echo "Desinstalação concluída!"