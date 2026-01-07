#!/bin/bash
# installparanaue.sh - Instala Kubernetes

echo "Preparando o Kubernetes..."
[ -f /etc/os-release ] && . /etc/os-release || exit 1
[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"
export DEBIAN_FRONTEND=noninteractive

# Ubuntu/Debian
if [[ "$ID" =~ ubuntu|debian ]]; then
    echo "Instalando K8s v1.35..."
    
    # Docker repo
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
        https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" \
        > /etc/apt/sources.list.d/docker.list
    
    # Kubernetes repo
    sudo curl -fsSL "https://pkgs.k8s.io/core:/stable:/v1.35/deb/Release.key" \
        -o /etc/apt/keyrings/kubernetes.asc
    sudo chmod a+r /etc/apt/keyrings/kubernetes.asc
    echo "deb [signed-by=/etc/apt/keyrings/kubernetes.asc] \
        https://pkgs.k8s.io/core:/stable:/v1.35/deb/ /" \
        > /etc/apt/sources.list.d/kubernetes.list
    
    apt-get update
    apt-get install -y containerd.io kubelet kubeadm kubectl
    apt-mark hold kubelet kubeadm kubectl

# RHEL/CentOS
elif [[ "$ID" =~ rhel|centos ]]; then
    echo "Instalando K8s v1.35..."
    yum update -y
    
    setenforce 0
    sed -i 's/SELINUX=enforcing/SELINUX=permissive/' /etc/selinux/config
    
    yum install -y yum-utils
    yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
    yum install -y containerd.io
    
    cat > /etc/yum.repos.d/kubernetes.repo <<'EOF'
[kubernetes]
name=Kubernetes
baseurl=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/
enabled=1
gpgcheck=1
gpgkey=https://pkgs.k8s.io/core:/stable:/v1.35/rpm/repodata/repomd.xml.key
EOF
    
    yum install -y kubelet kubeadm kubectl --disableexcludes=kubernetes
    systemctl enable --now kubelet
else
    echo "Distro não suportada"
    exit 1
fi

# Configuração do containerd
mkdir -p /etc/containerd
cat > /etc/containerd/config.toml <<'EOF'
version = 2
[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]
  SystemdCgroup = true
EOF

systemctl restart containerd
systemctl enable containerd

# Ajustes do sistema
swapoff -a
sed -i '/ swap / s/^/#/' /etc/fstab

cat > /etc/sysctl.d/k8s.conf <<'EOF'
net.ipv4.ip_forward = 1
EOF
sysctl --system >/dev/null

echo 'KUBELET_EXTRA_ARGS="--cgroup-driver=systemd"' > /etc/default/kubelet
systemctl restart kubelet 2>/dev/null

# Alias k=kubectl
echo 'alias k=kubectl' >> ~/.bashrc
source ~/.bashrc 2>/dev/null || true

echo "Pronto! Execute: sudo kubeadm init --pod-network-cidr=192.168.0.0/16"