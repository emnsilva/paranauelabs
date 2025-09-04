#!/bin/bash
# uninstallparanaue.sh - Desinstala o kit de observabilidade do Ministério (Multi-distro)

echo "Desinstalando infraestrutura de vigilância..."
echo "---------------------------------------------"

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

echo "Removendo containers Docker..."
docker rm -f $(docker ps -aq) 2>/dev/null || true

echo "Removendo imagens Docker..."
docker rmi -f $(docker images -q) 2>/dev/null || true

echo "Parando e desativando Docker..."
systemctl stop docker 2>/dev/null || true
systemctl disable docker 2>/dev/null || true

echo "Removendo Docker Compose..."
rm -f /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true

echo "Removendo pasta ministerio..."
rm -rf ministerio 2>/dev/null || true

# Remove pacotes conforme a distro
case $OS in
    ubuntu|debian)
        echo "Removendo pacotes (Ubuntu/Debian)..."
        apt-get remove -y -q stress-ng curl docker.io golang-go
        apt-get autoremove -y -q
        ;;
    rhel|centos|fedora)
        echo "Removendo pacotes (RHEL/CentOS/Fedora)..."
        yum remove -y -q stress-ng curl docker.io golang-go
        ;;
    *)
        echo "Distro não suportada: $OS"
        exit 1
        ;;
esac

echo "Limpando grupos de usuário..."
if id -nG "$SUDO_USER" | grep -q '\bdocker\b'; then
    gpasswd -d "$SUDO_USER" docker 2>/dev/null || true
fi

echo "Limpando cache Docker..."
docker system prune -a -f 2>/dev/null || true

echo "---------------------------------------------"
echo "Desinstalação concluída em $OS!"
echo ""
echo "SISTEMA LIMPO:"
echo "✓ Containers Docker removidos"
echo "✓ Imagens Docker removidas"
echo "✓ Docker Compose desinstalado"
echo "✓ Pacotes removidos"
echo "✓ Pasta ministerio eliminada"
echo ""
echo "O Ministério declara o sistema livre de vigilância."