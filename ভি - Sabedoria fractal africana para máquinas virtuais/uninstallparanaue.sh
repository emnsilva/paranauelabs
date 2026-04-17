#!/bin/bash
# uninstallparanaue.sh - Remove KVM + Docker CE completamente

set -e

echo "Removendo os paranauês..."

# Detecta a distribuição
[ -f /etc/os-release ] && . /etc/os-release && OS=$ID || { echo "Distro não detectada"; exit 1; }

# Verifica se é root, caso contrário executa com sudo
[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

# Salva o usuário original
ORIGINAL_USER=${SUDO_USER:-$USER}

echo ">>> Parando serviços..."
systemctl stop libvirtd docker 2>/dev/null || true
systemctl disable libvirtd docker 2>/dev/null || true

echo ">>> Removendo Docker completamente..."
# Remove containers, imagens, volumes e redes
docker rm -f $(docker ps -aq) 2>/dev/null || true
docker rmi -f $(docker images -q) 2>/dev/null || true
docker volume prune -f 2>/dev/null || true
docker network prune -f 2>/dev/null || true

# Remove pacotes Docker
case $OS in
    ubuntu|debian)
        apt-get remove -y -q docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin 2>/dev/null || true
        apt-get purge -y -q docker-ce docker-ce-cli containerd.io 2>/dev/null || true
        ;;
    rhel|centos)
        yum remove -y -q docker-ce docker-ce-cli containerd.io 2>/dev/null || true
        ;;
esac

# Remove diretórios do Docker
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker
rm -rf ~/.docker

echo ">>> Removendo KVM e Libvirt..."
case $OS in
    ubuntu|debian)
        apt-get purge -y -q qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils 2>/dev/null || true
        ;;
    rhel|centos)
        yum remove -y -q qemu-kvm libvirt-daemon libvirt-client bridge-utils virt-install 2>/dev/null || true
        ;;
esac

# Remove diretórios do Libvirt/KVM
rm -rf /var/lib/libvirt
rm -rf /etc/libvirt
rm -rf /var/log/libvirt

# Remove grupos do usuário
deluser $ORIGINAL_USER docker 2>/dev/null || true
deluser $ORIGINAL_USER libvirt 2>/dev/null || true
deluser $ORIGINAL_USER kvm 2>/dev/null || true

# Remove repositório do Docker (se existir)
case $OS in
    ubuntu|debian)
        rm -f /etc/apt/sources.list.d/docker.list
        rm -f /etc/apt/keyrings/docker.gpg
        rm -f /etc/apt/keyrings/docker.asc
        apt-get update -qq
        ;;
    rhel|centos)
        rm -f /etc/yum.repos.d/docker-ce.repo
        ;;
esac

# Limpa pacotes órfãos
case $OS in
    ubuntu|debian)
        apt-get autoremove -y -q --purge
        apt-get autoclean -y -q
        ;;
    rhel|centos)
        yum autoremove -y -q 2>/dev/null || true
        ;;
esac

# Remove imagem Alpine (se existir)
docker rmi alpine:latest 2>/dev/null || true

echo ">>> Remoção concluída! Reinicie o sistema para completar a limpeza."
sudo reboot now