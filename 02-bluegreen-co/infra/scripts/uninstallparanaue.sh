#!/usr/bin/env bash
# uninstall-paranaue.sh
set -e

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
[[ "$(id -u)" -eq 0 ]] || { echo "Rode como root (sudo)."; exit 1; }

log "1. Parando e removendo serviços do OpenRC..."
rc-service k3s stop 2>/dev/null || true
rc-service k3s-agent stop 2>/dev/null || true
rc-update del k3s default 2>/dev/null || true
rc-update del k3s-agent default 2>/dev/null || true
rm -f /etc/init.d/k3s /etc/init.d/k3s-agent

log "2. Matando processos remanescentes (k3s, containerd)..."
killall -9 k3s 2>/dev/null || true
killall -9 k3s-agent 2>/dev/null || true
killall -9 containerd 2>/dev/null || true
killall -9 containerd-shim 2>/dev/null || true

log "3. Executando desinstalador oficial (se existir)..."
if [[ -f /usr/local/bin/k3s-uninstall.sh ]]; then
    /usr/local/bin/k3s-uninstall.sh >/dev/null 2>&1 || true
elif [[ -f /usr/local/bin/k3s-agent-uninstall.sh ]]; then
    /usr/local/bin/k3s-agent-uninstall.sh >/dev/null 2>&1 || true
fi

log "4. Removendo binários e scripts..."
rm -f /usr/local/bin/k3s /usr/local/bin/k3s-killall.sh /usr/local/bin/k3s-uninstall.sh
rm -f /usr/local/bin/k3s-agent-uninstall.sh /usr/local/bin/kubectl /usr/local/bin/crictl /usr/local/bin/ctr

log "5. Desmontando e limpando dados e configurações..."
# Desmonta tudo que estiver pendurado nas pastas do k3s/kubelet
for mnt in $(grep -E '/var/lib/kubelet|/var/lib/rancher|/run/k3s' /proc/mounts | awk '{print $2}' | sort -r); do
    umount -l "$mnt" 2>/dev/null || true
done

# Agora apaga as pastas com segurança
rm -rf /etc/rancher /var/lib/rancher /var/lib/cni /etc/cni /var/lib/kubelet /run/k3s /run/flannel

log "6. Limpando interfaces de rede virtuais..."
ip link delete cni0 2>/dev/null || true
ip link delete flannel.1 2>/dev/null || true
ip link delete kube-ipvs0 2>/dev/null || true
ip link delete vxlan.calico 2>/dev/null || true

log "7. Limpando regras de firewall (iptables)..."
iptables -F 2>/dev/null || true
iptables -t nat -F 2>/dev/null || true
iptables -t mangle -F 2>/dev/null || true
iptables -X 2>/dev/null || true

log "=== Desinstalação concluída! A VM está limpa. ==="