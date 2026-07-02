#!/bin/bash
set -euo pipefail

. /etc/os-release

echo "==> Parando serviços..."
if [ "$ID" = "alpine" ]; then
    rc-service docker stop 2>/dev/null || true
else
    systemctl stop docker 2>/dev/null || true
fi
killall -9 ollama 2>/dev/null || true

# 1. Remove Docker
echo "==> Removendo Docker..."
case $ID in
    ubuntu|debian)
        apt-get purge -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker.io 2>/dev/null || true
        rm -f /etc/apt/sources.list.d/docker.list /etc/apt/keyrings/docker.gpg
        apt-get autoremove -y
        apt-get autoclean
        ;;
    rhel|centos)
        yum remove -y docker-ce docker-ce-cli containerd.io 2>/dev/null || true
        rm -f /etc/yum.repos.d/docker-ce.repo
        yum clean all
        ;;
    alpine)
        apk del docker docker-cli 2>/dev/null || true
        ;;
esac

# 2. Remove kubectl e minikube
echo "==> Removendo kubectl e minikube..."
rm -f /usr/local/bin/kubectl /usr/local/bin/minikube

# 3. Remove Ollama (caso tenha sido instalado manualmente)
echo "==> Removendo Ollama..."
rm -f /usr/local/bin/ollama /usr/bin/ollama /bin/ollama
rm -f /etc/systemd/system/ollama.service
userdel -r ollama 2>/dev/null || true
rm -rf /usr/share/ollama /usr/local/lib/ollama /etc/ollama /opt/ollama
rm -rf /root/.ollama
[ -n "${SUDO_USER:-}" ] && rm -rf /home/$SUDO_USER/.ollama

# 4. Remove o venv
echo "==> Removendo venv..."
rm -rf /opt/vigia

# 5. Remove usuário do grupo docker
if [ -n "${SUDO_USER:-}" ]; then
    if [ "$ID" = "alpine" ]; then
        delgroup $SUDO_USER docker 2>/dev/null || true
    else
        gpasswd -d $SUDO_USER docker 2>/dev/null || true
    fi
fi

# 6. Limpa caches
echo "==> Limpando caches..."
rm -rf /var/lib/docker /var/lib/minikube
rm -rf /root/.minikube /root/.kube
[ -n "${SUDO_USER:-}" ] && rm -rf /home/$SUDO_USER/.minikube /home/$SUDO_USER/.kube
rm -rf /root/.cache/pip
[ -n "${SUDO_USER:-}" ] && rm -rf /home/$SUDO_USER/.cache/pip

echo "Uninstall concluído. Sem rastro."
echo "Reiniciando em 10 segundos..."
sleep 10
reboot