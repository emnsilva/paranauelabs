#!/bin/sh
# installparanaue -- prepara a VM pro paranauelabs: dependencias base,
# docker + compose e o esqueleto do lab em /paranauelabs (mesma estrutura
# de pastas executavel do repo; arquivos chegam depois por scp).
# Uso: sudo sh installparanaue.sh   (alpine: doas sh installparanaue.sh)

. /etc/os-release

# 0. Usuario alvo (dono do esqueleto e do grupo docker)
USER_TARGET="${SUDO_USER:-${DOAS_USER:-$(id -un)}}"
LAB=/paranauelabs/02-onde-no-db-esta-carmen-sandiego

# 1. Instala dependencias base em 5 distros Linux
#    (git NAO entra: sem clone, nao ha comando de git na VM)
echo "==> Instalando dependencias base..."
case $ID in
    ubuntu|debian)
        export DEBIAN_FRONTEND=noninteractive
        apt-get update -y
        apt-get install -y ca-certificates curl make
        ;;
    rhel|centos)
        yum install -y ca-certificates curl make
        ;;
    alpine)
        apk update
        apk add ca-certificates curl make bash
        ;;
    *)
        echo "SO nao suportado: $ID"
        exit 1
        ;;
esac

# 2. Instala o Docker
echo "==> Instalando Docker..."
if [ "$ID" = "alpine" ]; then
    apk add docker docker-cli docker-cli-compose
    rc-update add docker default 2>/dev/null || true
    rc-service docker start 2>/dev/null || true
else
    curl -fsSL https://get.docker.com | sh
    systemctl enable --now docker
fi

# 3. Espera o daemon acordar
i=0
until docker info >/dev/null 2>&1; do
    i=$((i+1))
    [ $i -gt 15 ] && { echo "daemon docker nao acordou"; exit 1; }
    sleep 2
done

# 4. Adiciona o usuario no grupo docker
echo "==> Configurando usuario..."
if [ "$ID" = "alpine" ]; then
    addgroup "$USER_TARGET" docker 2>/dev/null || true
else
    usermod -aG docker "$USER_TARGET" 2>/dev/null || true
fi

# 5. Cria o esqueleto do lab (so o que executa na VM; docs ficam no Git)
echo "==> Criando esqueleto do lab..."
mkdir -p "$LAB"/scripts "$LAB"/data "$LAB"/collections "$LAB"/node-api "$LAB"/python-api
chown -R "$USER_TARGET:$USER_TARGET" /paranauelabs

# 6. Resumo
echo "  Setup concluido!"
echo "  Docker:  $(docker --version 2>/dev/null || echo 'N/A')"
echo "  Compose: $(docker compose version 2>/dev/null || echo 'N/A')"
echo "  Lab:     $LAB"
echo "  Proximo: scp dos arquivos para $LAB/ e make up"