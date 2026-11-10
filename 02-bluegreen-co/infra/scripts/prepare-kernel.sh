#!/usr/bin/env bash
# prepare-kernel.sh
# Executado via SSH como root dentro das VMs Alpine.

set -e

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
[[ "$(id -u)" -eq 0 ]] || { echo "Rode como root (sudo)."; exit 1; }

log "1. Instalando dependências de sistema (iptables)..."
apk add --no-cache iptables

log "2. Habilitando cgroups v2..."
rc-update add cgroups boot
rc-service cgroups start || true

log "3. Desativando swap..."
swapoff -a
sed -i '/[[:space:]]swap[[:space:]]/d' /etc/fstab

log "4. Carregando e persistindo módulos de kernel..."
echo "br_netfilter" > /etc/modules
echo "overlay" >> /etc/modules
echo "nf_conntrack" >> /etc/modules

modprobe br_netfilter
modprobe overlay
modprobe nf_conntrack

log "5. Configurando sysctl para Kubernetes..."
cat > /etc/sysctl.d/90-k3s.conf <<EOF
net.ipv4.ip_forward = 1
net.bridge.bridge-nf-call-iptables = 1
EOF

# Correção para o BusyBox do Alpine
sysctl -p /etc/sysctl.d/90-k3s.conf

log "6. Abrindo portas do firewall para o CloudNativePG..."
iptables -I INPUT -p tcp --dport 9443 -j ACCEPT || true
iptables -I FORWARD -p tcp --dport 9443 -j ACCEPT || true

log "=== Preparação concluída com sucesso! ==="