#!/usr/bin/env bash
# prepare-kernel.sh
set -e

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
[[ "$(id -u)" -eq 0 ]] || { echo "Rode como root (sudo)."; exit 1; }

log "1. Habilitando cgroups v2..."
rc-update add cgroups boot
rc-service cgroups start || true

log "2. Desativando swap..."
swapoff -a
sed -i '/[[:space:]]swap[[:space:]]/d' /etc/fstab

log "3. Carregando e persistindo módulos de kernel..."
echo "br_netfilter" > /etc/modules
echo "overlay" >> /etc/modules
echo "nf_conntrack" >> /etc/modules

modprobe br_netfilter
modprobe overlay
modprobe nf_conntrack

log "4. Configurando sysctl para Kubernetes..."
cat > /etc/sysctl.d/90-k3s.conf <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# AQUI ESTÁ A CORREÇÃO PARA O BUSYBOX DO ALPINE
sysctl -p /etc/sysctl.d/90-k3s.conf

log "=== Preparação concluída com sucesso! ==="