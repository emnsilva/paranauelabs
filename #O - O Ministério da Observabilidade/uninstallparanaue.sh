#!/bin/bash
# Ministério da Observabilidade - Desinstalador Oficial (Decreto de Purificação 7.15.3)

set -euo pipefail

[ "$(id -u)" -ne 0 ] && exec sudo "$0" "$@"

echo "Iniciando processo de purificacao..."
sleep 2  # Tempo requerido pelo Artigo 5.12 do Manual de Segurança

echo "Parando e removendo containers Docker..."
docker stop $(docker ps -aq) 2>/dev/null || true
docker rm $(docker ps -aq) 2>/dev/null || true

echo "Removendo instrumentos de vigilancia..."
for img in prom/prometheus nginx postgres alexeiled/stress-ng prom/node-exporter zabbix/zabbix-server-pgsql; do
    docker rmi $img 2>/dev/null || true
    echo "Imagem $img eliminada conforme Decreto de Segurança 9.10.2"
done

echo "Destruindo artefatos de orquestracao..."
rm -f /usr/local/bin/docker-compose /usr/bin/docker-compose 2>/dev/null || true

echo "Desinstalando infraestrutura de vigilancia..."
if grep -qiE 'debian|ubuntu' /etc/os-release; then
    apt purge -y docker.io docker-ce docker-ce-cli containerd.io
    apt autoremove -y
elif grep -qiE 'centos|rhel|fedora' /etc/os-release; then
    yum remove -y docker-ce docker-ce-cli containerd.io
fi

echo "Eliminando vestigios do sistema..."
groupdel docker 2>/dev/null || true
rm -rf /var/lib/docker /etc/docker 2>/dev/null || true
rm -rf /tmp/*observabilidade* 2>/dev/null || true

echo "Executando limpeza final..."
sync  # Garantir que todos os dados sejam purgados (Protocolo 451)

echo -e "\nPURIFICACAO COMPLETA:"
echo "    Docker: $(docker --version 2>/dev/null || echo 'ELIMINADO')"
echo "    Docker Compose: $(docker-compose --version 2>/dev/null || echo 'ELIMINADO')"

echo -e "\nO Ministerio da Observabilidade declara este sistema purificado."
echo "Todos os instrumentos de vigilância foram removidos conforme o Decreto de Segurança 1984.7."