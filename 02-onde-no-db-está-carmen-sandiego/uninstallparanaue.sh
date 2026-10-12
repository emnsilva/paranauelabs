#!/bin/sh
# uninstallparanaue.sh -- devolve a VM ao estado pre-installparanaue.
# Remove: docker (pacotes, servico, dados, repositorio), grupo docker,
# pacotes base (ca-certificates, curl, make), ~/.docker e /paranauelabs.

. /etc/os-release

# 0. Usuario alvo (dono do ~/.docker)
USER_TARGET="${SUDO_USER:-${DOAS_USER:-$(id -un)}}"
USER_HOME=$(grep "^${USER_TARGET}:" /etc/passwd | cut -d: -f6)

# 1. Para e desabilita o servico docker
echo "==> Parando docker..."
if [ "$ID" = "alpine" ]; then
    rc-service docker stop 2>/dev/null || true
    rc-service containerd stop 2>/dev/null || true
    rc-update del docker default 2>/dev/null || true
else
    systemctl disable --now docker.socket docker 2>/dev/null || true
    systemctl stop containerd 2>/dev/null || true
fi

# 2. Remove os pacotes (docker + base do install)
echo "==> Removendo pacotes..."
case $ID in
    ubuntu|debian)
        export DEBIAN_FRONTEND=noninteractive
        apt-get purge -y docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras \
            ca-certificates curl make
        apt-get autoremove --purge -y
        ;;
    rhel|centos)
        yum remove -y docker-ce docker-ce-cli containerd.io \
            docker-buildx-plugin docker-compose-plugin docker-ce-rootless-extras \
            ca-certificates curl make
        yum autoremove -y
        ;;
    alpine)
        apk del docker docker-cli docker-cli-compose containerd \
            ca-certificates curl make
        ;;
    *)
        echo "SO nao suportado: $ID"
        exit 1
        ;;
esac

# 3. Remove dados, configs e repositorio do docker
echo "==> Removendo dados e configs do docker..."
rm -rf /var/lib/docker /var/lib/containerd /etc/docker /etc/conf.d/docker \
       /run/docker.sock /run/docker.pid /run/containerd
rm -f /etc/apt/sources.list.d/docker.list \
      /etc/apt/sources.list.d/docker-ce.list \
      /etc/apt/keyrings/docker.asc \
      /etc/apt/keyrings/docker.gpg \
      /usr/share/keyrings/docker-archive-keyring.gpg \
      /etc/yum.repos.d/docker-ce.repo

# 4. Remove o grupo docker
echo "==> Removendo grupo docker..."
if [ "$ID" = "alpine" ]; then
    delgroup "$USER_TARGET" docker 2>/dev/null || true
    delgroup docker 2>/dev/null || true
else
    gpasswd -d "$USER_TARGET" docker 2>/dev/null || true
    groupdel docker 2>/dev/null || true
fi

# 5. Remove ~/.docker, o lab inteiro e residuos de installs antigos
echo "==> Removendo ~/.docker, /paranauelabs e residuos antigos..."
rm -rf "$USER_HOME/.docker" /paranauelabs
rm -rf /usr/local/lib/node_modules /usr/local/include/node "$USER_HOME/.local/share/uv"
rm -f /usr/local/bin/uv /usr/local/bin/uvx /usr/local/bin/node \
      /usr/local/bin/npm /usr/local/bin/npx /usr/local/bin/corepack

# 6. Resumo
echo "  Uninstall concluido!"
echo "  Docker:          $(command -v docker >/dev/null 2>&1 && echo 'AINDA PRESENTE' || echo removido)"
echo "  /var/lib/docker: $([ -d /var/lib/docker ] && echo 'AINDA PRESENTE' || echo removido)"
echo "  /paranauelabs:   $([ -d /paranauelabs ] && echo 'AINDA PRESENTE' || echo removido)"
echo "  grupo docker:    $(grep -q '^docker:' /etc/group && echo 'AINDA PRESENTE' || echo removido)"