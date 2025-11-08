#!/bin/bash
# uninstallparanaue.sh - Limpa todo o arsenal do comboio containerizado

echo "Desmontando o comboio containerizado..."
echo "---------------------------------------"

# Verifica se é root, caso contrário executa com sudo
[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

echo "Parando e removendo todos os containers..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo "Removendo todas as imagens Docker..."
docker rmi $(docker images -q) 2>/dev/null || true

echo "Removendo volumes e networks não utilizados..."
docker volume prune -f
docker network prune -f
docker system prune -a -f --volumes

echo "Desmontando a locomotiva (Docker Compose)..."
rm -f /usr/local/bin/docker-compose
rm -f /usr/bin/docker-compose

echo "Removendo aplicações instaladas..."

# Detecta a distribuição
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Não foi possível detectar a distro"
    exit 1
fi

case $OS in
    ubuntu|debian)
        echo "Removendo Postman (Snap)..."
        snap remove postman --purge 2>/dev/null || true
        
        echo "Removendo Docker..."
        apt-get remove -y -q docker.io docker-compose
        apt-get autoremove -y -q
        ;;
    rhel|centos)
        echo "Removendo Postman manualmente..."
        rm -rf /opt/Postman
        rm -f /usr/bin/postman
        
        # Remove o atalho .desktop do usuário correto
        USER_HOME=$(getent passwd $SUDO_USER | cut -d: -f6)
        rm -f $USER_HOME/.local/share/applications/postman.desktop 2>/dev/null || true
        
        echo "Removendo Docker..."
        yum remove -y -q docker.io docker-compose
        ;;
esac

echo "Removendo estrutura de pastas..."
rm -rf comboio
rm -rf /tmp/paranaue-setup

echo "Removendo usuário do grupo Docker..."
if command -v docker &>/dev/null; then
    gpasswd -d $SUDO_USER docker 2>/dev/null || true
fi

echo "Limpando arquivos de configuração..."
rm -f /etc/apt/sources.list.d/docker.list 2>/dev/null || true
rm -f /etc/yum.repos.d/docker-ce.repo 2>/dev/null || true

echo "Reiniciando serviços..."
systemctl daemon-reload 2>/dev/null || true

echo "---------------------------------------"
echo "Desinstalação completa!"