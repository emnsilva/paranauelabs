#!/bin/bash
# installparanaue.sh - Instala as ferramentas para o cluster Kubernetes

echo "Preparando o solo do Kubernetes..."
echo "-------------------------------------------"

# Detecta distribuição
[ -f /etc/os-release ] && . /etc/os-release || { echo "ERRO: Não foi possível detectar a distro"; exit 1; }
[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"
export DEBIAN_FRONTEND=noninteractive

# Instalação por distro
case $ID in
    ubuntu|debian)
    # 1. Configuração de repositório
    echo "Configurando repositório Kubernetes..."
    K8S_VERSION="v1.30"
    [ "$VERSION_ID" = "24.04" ] || K8S_VERSION="v1.29"
    curl -fsSL "https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/Release.key" | \
        gpg --dearmor -o /usr/share/keyrings/kubernetes-keyring.gpg
    echo "deb [signed-by=/usr/share/keyrings/kubernetes-keyring.gpg] https://pkgs.k8s.io/core:/stable:/$K8S_VERSION/deb/ /" \
        > /etc/apt/sources.list.d/kubernetes.list
    
    # 2. Container runtime e Kubernetes
    echo "Instalando Kubernetes e dependências..."
    apt-get update -y -q && apt-get upgrade -y -q
    apt-get install -y containerd kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl
    ;;
        
    rhel|centos)
    # 1. Atualização e configuração básica
    echo "Atualizando sistema e configurando SELinux..."
    yum update -y
    setenforce 0
    sed -i 's/^SELINUX=enforcing$/SELINUX=permissive/' /etc/selinux/config
    
    # 2. Container runtime
    echo "Instalando containerd..."
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y containerd.io
    
    # 3. Kubernetes
    echo "Configurando repositório Kubernetes..."
    cat > /etc/yum.repos.d/kubernetes.repo <<EOF
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.29/rpm/repodata/repomd.xml.key
EOF
    
    echo "Instalando Kubernetes..."
    yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    systemctl enable --now kubelet
    ;;
esac

# Configuração comum
echo "Configurando containerd..."
mkdir -p /etc/containerd

# DESMASCARAR o serviço se estiver mascarado
systemctl unmask containerd 2>/dev/null || true
containerd config default 2>/dev/null | \
    sed 's/SystemdCgroup = false/SystemdCgroup = true/' > /etc/containerd/config.toml
systemctl restart containerd && systemctl enable containerd

echo "Ajustando sistema..."
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

cat > /etc/sysctl.d/k8s.conf <<EOF
net.bridge.bridge-nf-call-ip6tables = 1
net.bridge.bridge-nf-call-iptables = 1
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null

modprobe br_netfilter overlay
cat > /etc/modules-load.d/k8s.conf <<EOF
br_netfilter
overlay
EOF

echo 'KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"' > /etc/default/kubelet
systemctl daemon-reload
systemctl restart kubelet 2>/dev/null

# Resumo
echo "-------------------------------------------"
echo "Instalação concluída!"
echo ""
echo "Ferramentas instaladas:"
command -v containerd >/dev/null && echo "✓ containerd" || echo "✗ containerd"
command -v kubelet >/dev/null && echo "✓ kubelet"       || echo "✗ kubelet"
command -v kubeadm >/dev/null && echo "✓ kubeadm"       || echo "✗ kubeadm"
command -v kubectl >/dev/null && echo "✓ kubectl"       || echo "✗ kubectl"
echo "-------------------------------------------"