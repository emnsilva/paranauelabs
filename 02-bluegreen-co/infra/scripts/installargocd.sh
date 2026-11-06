#!/usr/bin/env bash
# installargocd.sh
set -e

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
[[ "$(id -u)" -eq 0 ]] || { echo "Rode como root (sudo)."; exit 1; }

# Aponta o Helm para o kubeconfig do k3s
export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

log "1. Instalando Helm..."
apk add --no-cache helm

log "2. Adicionando repositório do Argo CD..."
helm repo add argo https://argoproj.github.io/argo-helm
helm repo update

log "3. Instalando Argo CD (com timeout estendido e recursos ajustados)..."
# A flag --wait foi removida. O Helm não vai mais bloquear.
# O timeout foi aumentado para 10 minutos como margem de segurança.
# Os recursos foram reduzidos para caber nas ResourceQuotas do lab.
helm upgrade --install argocd argo/argo-cd \
  --namespace argocd \
  --create-namespace \
  --timeout 10m \
  --set server.service.type=NodePort \
  --set server.service.nodePortHttps=30443 \
  --set applicationSet.enabled=false \
  --set dex.enabled=false \
  --set notifications.enabled=false \
  --set controller.resources.requests.memory=256Mi \
  --set controller.resources.limits.memory=512Mi \
  --set repoServer.resources.requests.memory=256Mi \
  --set repoServer.resources.limits.memory=512Mi \
  --set server.resources.requests.memory=64Mi \
  --set server.resources.limits.memory=128Mi

log "4. Comando enviado ao cluster. Os pods do Argo CD estão iniciando em segundo plano."
log "Aguarde 1 a 2 minutos e verifique o status com:"
log "sudo k3s kubectl get pods -n argocd"