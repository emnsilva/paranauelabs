#!/bin/bash
set -e

. /etc/os-release

case $ID in
    ubuntu|debian)
        apt-get update -y
        apt-get install -y ca-certificates curl gnupg lsb-release
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://download.docker.com/linux/$ID/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
        echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
        apt-get update -y
        apt-get install -y docker-ce docker-ce-cli containerd.io
        systemctl enable --now docker
        ;;
    rhel|centos)
        yum install -y yum-utils curl
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum install -y docker-ce docker-ce-cli containerd.io
        systemctl enable --now docker
        ;;
    alpine)
        apk update
        apk add docker docker-cli curl gcompat
        rc-update add docker boot
        rc-service docker start
        ;;
    *)
        echo "SO nao suportado: $ID"
        exit 1
        ;;
esac

curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
chmod +x kubectl && mv kubectl /usr/local/bin/

curl -LO "https://storage.googleapis.com/minikube/releases/latest/minikube-linux-amd64"
chmod +x minikube-linux-amd64 && mv minikube-linux-amd64 /usr/local/bin/minikube

if [ -n "$SUDO_USER" ]; then
    if [ "$ID" = "alpine" ]; then
        addgroup $SUDO_USER docker
    else
        usermod -aG docker $SUDO_USER
    fi
    echo "Usuario $SUDO_USER adicionado ao grupo docker. Reiniciando..."
fi

reboot