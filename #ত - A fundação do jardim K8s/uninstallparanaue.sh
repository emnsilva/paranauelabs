#!/bin/bash
# uninstallparanaue.sh - Remove completamente o Kubernetes e limpa todos os rastros

echo "Limpando completamente o terreno do Kubernetes..."
echo "-------------------------------------------"

[ -f /etc/os-release ] && . /etc/os-release || { echo "ERRO: Não foi possível detectar a distro"; exit 1; }
[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

# 1. Parar e desabilitar todos os serviços
echo "Parando serviços..."
for service in kubelet containerd docker; do
    systemctl stop $service 2>/dev/null
    systemctl disable $service 2>/dev/null
    systemctl mask $service 2>/dev/null 2>/dev/null
done

# 2. Remover containers e imagens
echo "Removendo containers e imagens..."
crictl rm -f $(crictl ps -aq 2>/dev/null) 2>/dev/null
crictl rmi -f $(crictl images -q 2>/dev/null) 2>/dev/null
docker rm -f $(docker ps -aq 2>/dev/null) 2>/dev/null
docker rmi -f $(docker images -q 2>/dev/null) 2>/dev/null

# 3. Remover pacotes Kubernetes
echo "Removendo Kubernetes..."
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

# 4. Remover container runtime
echo "Removendo container runtime..."
case $ID in
    ubuntu|debian)
        apt-get purge -y containerd runc
        apt-get autoremove -y --purge
        ;;
    rhel|centos)
        yum remove -y containerd.io runc docker-ce docker-ce-cli
        rm -f /etc/yum.repos.d/docker-ce.repo
        ;;
esac

# 5. Remover dependências específicas
echo "Removendo dependências..."
case $ID in
    rhel|centos)
        yum remove -y yum-utils device-mapper-persistent-data lvm2
        ;;
esac

# 6. Limpeza nuclear de diretórios
echo "Limpando diretórios do Kubernetes..."
rm -rf /etc/kubernetes
rm -rf /var/lib/kubelet
rm -rf /var/lib/etcd
rm -rf /var/lib/cni
rm -rf /etc/cni
rm -rf ~/.kube
rm -rf /root/.kube
rm -rf /home/*/.kube 2>/dev/null

echo "Limpando diretórios de containers..."
rm -rf /var/run/containerd
rm -rf /var/lib/containerd
rm -rf /var/run/docker
rm -rf /var/lib/docker
rm -rf /etc/docker

# 7. Reverter configurações de sistema
echo "Revertendo configurações..."
rm -f /etc/containerd/config.toml
rm -f /etc/default/kubelet
rm -f /etc/sysctl.d/k8s.conf
rm -f /etc/modules-load.d/k8s.conf

echo "Reativando swap..."
sed -i '/ swap / s/^#//g' /etc/fstab 2>/dev/null

echo "Revertendo SELinux..."
if [ "$ID" = "rhel" ] || [ "$ID" = "centos" ]; then
    sed -i 's/^SELINUX=permissive$/SELINUX=enforcing/' /etc/selinux/config 2>/dev/null
fi

# 8. Limpar caches e dados temporários
echo "Limpando caches..."
case $ID in
    ubuntu|debian)
        apt-get clean
        apt-get autoclean
        ;;
    rhel|centos)
        yum clean all
        ;;
esac

rm -rf /var/cache/apt/* 2>/dev/null
rm -rf /var/cache/yum/* 2>/dev/null

# 9. Remover módulos do kernel (opcional)
echo "Removendo módulos do kernel..."
rmmod br_netfilter 2>/dev/null
rmmod overlay 2>/dev/null

# 10. Recarregar sysctl
echo "Recarregando configurações do kernel..."
sysctl --system 2>/dev/null || true

# 11. Remover arquivos de configuração do usuário
echo "Limpando configurações de usuário..."
find /home -name "kube" -type d -exec rm -rf {} + 2>/dev/null
find /root -name "kube" -type d -exec rm -rf {} + 2>/dev/null

# 12. Limpar logs
echo "Limpando logs relacionados..."
find /var/log -name "*kube*" -exec rm -f {} + 2>/dev/null
find /var/log -name "*docker*" -exec rm -f {} + 2>/dev/null
find /var/log -name "*containerd*" -exec rm -f {} + 2>/dev/null
journalctl --vacuum-time=1h 2>/dev/null

sudo reboot now

echo "-------------------------------------------"
echo "LIMPESA COMPLETA CONCLUÍDA!"
echo ""
echo "Sistema limpo. Para remoção total:"
echo "1. Após reboot, verifique com:"
echo "   - kubeadm version (deve falhar)"
echo "   - kubectl version (deve falhar)"
echo "   - systemctl status containerd (não deve existir)"
echo "-------------------------------------------"