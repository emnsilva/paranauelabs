#!/bin/bash
set -e

. /etc/os-release

case $ID in
    ubuntu|debian)
        apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        apt-get autoremove -y
        rm -rf /etc/apt/sources.list.d/docker.list
        rm -rf /etc/apt/keyrings/docker.gpg
        apt-get update
        ;;
    rhel|centos)
        yum remove -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
        yum autoremove -y
        rm -rf /etc/yum.repos.d/docker-ce.repo
        ;;
    alpine)
        rc-service docker stop
        apk del docker docker-cli
        rc-update del docker boot 2>/dev/null || true
        ;;
    *)
        echo "SO nao suportado: $ID"
        exit 1
        ;;
esac

rm -f /usr/local/bin/kubectl
rm -f /usr/local/bin/minikube
rm -rf /var/lib/docker
rm -rf /var/lib/containerd
rm -rf /etc/docker

reboot