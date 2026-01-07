#!/bin/bash
# uninstallparanaue.sh - Remove Kubernetes completamente

echo "🧹 NUCLEAR: Removendo Kubernetes..."
[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

# 1. PARAR TUDO
echo "⏹️  Parando serviços..."
systemctl stop kubelet containerd docker 2>/dev/null || true
kubeadm reset -f 2>/dev/null
crictl rm -f $(crictl ps -aq 2>/dev/null) 2>/dev/null

# 2. REMOVER KUBERNETES
if [ -f /etc/os-release ]; then
    . /etc/os-release
    case $ID in
        ubuntu|debian)
            apt-mark unhold kubelet kubeadm kubectl 2>/dev/null
            apt-get purge -y kubelet kubeadm kubectl kubernetes-cni cri-tools
            apt-get autoremove -y --purge
            rm -f /etc/apt/sources.list.d/kubernetes.list
            rm -f /usr/share/keyrings/kubernetes-keyring.gpg
            ;;
        rhel|centos)
            yum remove -y kubelet kubeadm kubectl kubernetes-cni cri-tools
            yum autoremove -y
            rm -f /etc/yum.repos.d/kubernetes.repo
            ;;
    esac
fi

# 3. REMOVER CONTAINERD/DOCKER
case $ID in
    ubuntu|debian)
        apt-get purge -y containerd.io docker-ce docker-ce-cli runc
        rm -f /etc/apt/sources.list.d/docker.list
        ;;
    rhel|centos)
        yum remove -y containerd.io docker-ce docker-ce-cli runc
        rm -f /etc/yum.repos.d/docker-ce.repo
        ;;
esac

# 4. LIMPEZA NUCLEAR DE DIRETÓRIOS
echo "🗑️  Apagando diretórios..."
rm -rf /etc/kubernetes /var/lib/kubelet /var/lib/etcd /var/lib/cni /etc/cni
rm -rf ~/.kube /root/.kube /home/*/.kube 2>/dev/null
rm -rf /var/lib/containerd /var/lib/docker /run/containerd /run/docker
rm -rf /etc/containerd /etc/docker

# 5. REVERTER CONFIGURAÇÕES
echo "↩️  Revertendo configurações..."
rm -f /etc/default/kubelet /etc/sysctl.d/k8s.conf /etc/modules-load.d/k8s.conf
sed -i '/ swap / s/^#//g' /etc/fstab 2>/dev/null
[ "$ID" = "rhel" ] || [ "$ID" = "centos" ] && \
    sed -i 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config 2>/dev/null

# 6. REMOVER ALIASES
echo "🚮 Removendo aliases..."
sed -i '/alias k=kubectl/d' ~/.bashrc /root/.bashrc /home/*/.bashrc 2>/dev/null
rm -f /etc/profile.d/k8s-aliases.sh

# 7. LIMPAR CACHE
echo "🧼 Limpando cache..."
apt-get clean 2>/dev/null || yum clean all 2>/dev/null
journalctl --vacuum-time=1h 2>/dev/null

# 8. RECARREGAR
systemctl daemon-reload
sysctl --system 2>/dev/null || true

sudo reboot now

echo "✅ REMOÇÃO COMPLETA!"