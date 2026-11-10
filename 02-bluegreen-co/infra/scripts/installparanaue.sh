#!/usr/bin/env bash
# installparanaue.sh
# Uso:
#   Server: sudo ./installparanaue.sh server
#   Agent:  sudo ./installparanaue.sh agent <IP_DO_CONTROL_PLANE> <TOKEN>

set -e

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
[[ "$(id -u)" -eq 0 ]] || { echo "Rode como root (sudo)."; exit 1; }

MODE="${1:-server}"
CP_IP="${2:-}"
TOKEN="${3:-}"
K3S_VERSION="v1.36.5+k3s1"

if [[ "$MODE" != "server" && "$MODE" != "agent" ]]; then
  echo "Erro: O primeiro argumento deve ser 'server' ou 'agent'."
  exit 1
fi

log "1. Instalando dependências de sistema (iptables, curl)..."
apk add --no-cache iptables curl

log "2. Verificando se o k3s já está instalado..."
if command -v k3s >/dev/null 2>&1; then
    log "k3s já está instalado. Nada a fazer."
    exit 0
fi

log "3. Instalando o k3s versão ${K3S_VERSION} no modo: ${MODE}..."

if [[ "$MODE" == "server" ]]; then
    # Desabilita o Traefik no server para economizar RAM e evitar conflito com o Ingress-Nginx
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION}" INSTALL_K3S_EXEC="server --disable traefik" sh -
    
    log "Aguardando o servidor inicializar..."
    sleep 10
    log "=========================================================="
    log "TOKEN DO NÓ (copie para usar nos workers):"
    cat /var/lib/rancher/k3s/server/node-token
    log "=========================================================="
    
elif [[ "$MODE" == "agent" ]]; then
    [[ -z "$CP_IP" || -z "$TOKEN" ]] && { echo "Erro: Para agent, informe o IP do control plane e o Token."; exit 1; }
    
    curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION="${K3S_VERSION}" K3S_URL="https://${CP_IP}:6443" K3S_TOKEN="${TOKEN}" sh -
fi

log "=== Instalação do k3s concluída! ==="