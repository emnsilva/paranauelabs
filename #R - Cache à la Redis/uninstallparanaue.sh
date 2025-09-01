#!/bin/bash
echo "Desinstalando kit de ferramentas..."
echo "--------------------------------------"

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Nao foi possível detectar a distro"
    exit 1
fi

# Remover usuário do grupo docker
echo "Removendo permissoes..."
CURRENT_USER=${SUDO_USER:-$USER}
sudo deluser $CURRENT_USER docker 2>/dev/null || true

# Parar e desativar Docker
echo "Parando servico Docker..."
sudo systemctl stop docker 2>/dev/null || true
sudo systemctl disable docker 2>/dev/null || true

# Remover imagens Docker
echo "Removendo imagens Docker..."
for img in postgres:15 redis:7-alpine node:18-alpine; do
    echo "Removendo: $img"
    sudo docker rmi $img 2>/dev/null || true
done

# Remover Docker Compose
echo "Removendo Docker Compose..."
sudo rm -f /usr/local/bin/docker-compose 2>/dev/null || true
sudo rm -f /usr/bin/docker-compose 2>/dev/null || true

# Remover estrutura de diretórios do projeto
echo "Removendo estrutura do projeto..."
rm -rf ~/lab 2>/dev/null || true

# Desinstalar pacotes conforme a distro
echo "Desinstalando pacotes..."
case $OS in
    ubuntu|debian)
        sudo apt-get remove -y --purge nodejs docker.io docker-compose curl git
        sudo apt-get autoremove -y
        sudo apt-get clean
        ;;
    rhel|centos|fedora)
        sudo yum remove -y nodejs docker.io curl git
        sudo yum clean all
        ;;
    *)
        echo "Distro nao suportada: $OS"
        exit 1
        ;;
esac

# Remover repositórios adicionados do Node.js
echo "Removendo repositórios adicionados..."
case $OS in
    ubuntu|debian)
        sudo rm -f /etc/apt/sources.list.d/nodesource.list 2>/dev/null || true
        sudo rm -f /etc/apt/trusted.gpg.d/nodesource.gpg 2>/dev/null || true
        ;;
esac

# Limpar cache e arquivos temporários
echo "Limpando cache..."
sudo rm -rf /var/lib/docker 2>/dev/null || true
sudo rm -rf /var/lib/containerd 2>/dev/null || true
sudo rm -rf ~/.npm 2>/dev/null || true
sudo rm -rf ~/.node-gyp 2>/dev/null || true
sudo rm -rf ~/.docker 2>/dev/null || true

# Verificar remoção
echo -e "\n VERIFICACAO DE DESINSTALACAO:"
echo "    Docker: $(docker --version 2>/dev/null || echo 'REMOVIDO')"
echo "    Docker Compose: $(docker-compose --version 2>/dev/null || echo 'REMOVIDO')"
echo "    Node.js: $(node --version 2>/dev/null || echo 'REMOVIDO')"
echo "    npm: $(npm --version 2>/dev/null || echo 'REMOVIDO')"
echo "    Diretorio lab: $(ls ~/lab 2>/dev/null || echo 'REMOVIDO')"

echo -e "\n Desinstalacao concluida! Sistema limpo."