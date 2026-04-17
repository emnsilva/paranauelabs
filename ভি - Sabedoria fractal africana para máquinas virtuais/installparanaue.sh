#!/bin/bash
# installparanaue.sh - Instala KVM + Docker CE no Linux

set -e

echo "Instalando os paranauês..."

# Detecta a distribuição
[ -f /etc/os-release ] && . /etc/os-release && OS=$ID || { echo "Distro não detectada"; exit 1; }

# Verifica se é root, caso contrário executa com sudo
[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

# Instala pacotes necessários
case $OS in
    ubuntu|debian)
        echo "Instalando (Ubuntu/Debian)..."
        apt-get update -qq && apt-get upgrade -y -qq
        apt-get install -y curl qemu-kvm libvirt-daemon-system libvirt-clients bridge-utils ;;

    rhel|centos)
        echo "Instalando (RHEL/CentOS)..."
        yum update -y -q && yum install -y -q yum-utils curl
        yum install -y -q qemu-kvm libvirt-daemon libvirt-client bridge-utils virt-install ;;
esac

# Instala o Docker
echo ">>> Instalando Docker..."
curl -fsSL https://get.docker.com | sh

# Ativa o libvirt e o Docker
echo "Ativando o libvirt e o Docker..."
systemctl enable --now libvirtd docker && usermod -aG docker,libvirt $SUDO_USER 2>/dev/null || true
chmod 666 /dev/kvm 2>/dev/null || true

# Prepara a imagem do container
echo "Preparando a imagem..."
for img in alpine:latest; do 
    docker pull $img
done

echo "Instalação concluída!"