#!/bin/bash
# removeparanaue-completo.sh - Remove COMPLETAMENTE com purge tudo do script de instalação

echo "REMOVENDO TUDO - LIMPEZA COMPLETA..."
echo "------------------------------------"

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Nao foi possível detectar a distro"
    exit 1
fi

# Função para remover Postman manual
remove_postman_manual() {
    echo "Removendo Postman manual..."
    sudo rm -rf /opt/Postman
    sudo rm -f /usr/bin/postman
    sudo rm -f /usr/local/bin/postman
    rm -f ~/.local/share/applications/postman.desktop
    rm -rf ~/.config/Postman
}

# Função para limpar Go
clean_go() {
    echo "Limpando ambiente Go..."
    rm -rf ~/go
    rm -rf ~/.cache/go-build
    if [ -f ~/.bashrc ]; then
        sed -i '/GOPATH\|GOROOT/d' ~/.bashrc
    fi
    if [ -f ~/.profile ]; then
        sed -i '/GOPATH\|GOROOT/d' ~/.profile
    fi
}

case $OS in
    ubuntu|debian)
        echo "Remoção completa com purge (Ubuntu/Debian)..."
        
        # Remove snaps
        sudo snap remove postman 2>/dev/null || true
        sudo snap remove core 2>/dev/null || true
        
        # Remove pacotes com purge
        sudo apt-get remove -y --purge \
            python3-full \
            python3-flask \
            golang-go \
            sqlite3 \
            snapd \
            curl
        
        # Remove dependências não utilizadas
        sudo apt-get autoremove -y --purge
        
        # Limpa cache
        sudo apt-get autoclean -y
        ;;
    
    rhel|centos|fedora)
        echo "Remoção completa (RHEL/CentOS/Fedora)..."
        
        # Remove Postman manual
        remove_postman_manual
        
        # Remove pacotes
        if command -v dnf &> /dev/null; then
            sudo dnf remove -y \
                python3-devel \
                python3-flask \
                golang \
                sqlite \
                wget \
                curl
        else
            sudo yum remove -y \
                python3-devel \
                python3-flask \
                golang \
                sqlite \
                wget \
                curl
        fi
        
        # Remove EPEL se foi instalado
        if [[ "$OS" == "centos" || "$OS" == "rhel" ]]; then
            sudo yum remove -y epel-release 2>/dev/null || true
        fi
        
        # Limpa cache
        if command -v dnf &> /dev/null; then
            sudo dnf clean all
        else
            sudo yum clean all
        fi
        ;;
    *)
        echo "Distribuição '$OS' não suportada por este script." >&2
        exit 1
        ;;
esac

# --- LIMPEZA NUCLEAR DE ARQUIVOS DE USUÁRIO ---
echo "------------------------------------"
echo "Limpando arquivos do usuário..."

# Remove diretório do projeto e módulo Go
rm -rf ~/apis
rm -rf ~/api-go

# Limpa ambiente Go
clean_go

# Remove módulos Go
rm -rf ~/go/pkg/mod
rm -f ~/go.mod ~/go.sum

# Remove cache pip e pacotes Python
rm -rf ~/.cache/pip
rm -rf ~/.local/lib/python*
rm -rf ~/.local/share/applications/postman*

# Remove arquivos temporários
rm -f ~/postman.tar.gz
rm -rf /tmp/postman*

# Remove configurações
rm -rf ~/.config/go
rm -rf ~/.cache/go-build

# Remove histórico de comandos relacionados
if [ -f ~/.bash_history ]; then
    sed -i '/\/apis\|postman\|go mod\|pip install\|go get/d' ~/.bash_history
fi

# Recarrega variáveis de ambiente
if [ -n "$BASH" ]; then
    source ~/.bashrc 2>/dev/null || true
fi

echo "------------------------------------"
echo "LIMPEZA COMPLETA CONCLUÍDA!"