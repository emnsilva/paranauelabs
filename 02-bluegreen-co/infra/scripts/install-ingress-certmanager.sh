#!/usr/bin/env bash
# install-ingress-certmanager.sh
set -e

log() { printf '[%s] %s\n' "$(date '+%H:%M:%S')" "$*"; }
[[ "$(id -u)" -eq 0 ]] || { echo "Rode como root (sudo)."; exit 1; }

export KUBECONFIG=/etc/rancher/k3s/k3s.yaml

# --- Limpeza de tentativas anteriores ---
log "0. Limpando instalação anterior do cert-manager (se existir)..."
helm uninstall cert-manager -n cert-manager 2>/dev/null || true
k3s kubectl delete ns cert-manager --ignore-not-found=true || true

log "1. Desabilitando o Traefik..."
if k3s kubectl get deployment traefik -n kube-system >/dev/null 2>&1; then
    k3s kubectl delete deployment traefik -n kube-system || true
    k3s kubectl delete svc traefik -n kube-system || true
fi

log "2. Instalando Ingress-Nginx..."
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
helm upgrade --install ingress-nginx ingress-nginx/ingress-nginx \
  --namespace ingress-nginx \
  --set controller.service.type=NodePort \
  --set controller.service.nodePorts.http=30081 \
  --set controller.service.nodePorts.https=30444 \
  --set controller.resources.requests.cpu=100m \
  --set controller.resources.requests.memory=128Mi \
  --set controller.resources.limits.memory=256Mi \
  --wait --timeout 5m

log "3. Instalando Cert-Manager (com verificação de API desabilitada)..."
helm repo add jetstack https://charts.jetstack.io
helm repo update

# AQUI ESTÃO AS CORREÇÕES:
# --timeout 10m: Aumenta o tempo de espera do Helm.
# --set startupapicheck.enabled=false: Desabilita o job de verificação que costuma travar.
helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --set installCRDs=true \
  --set startupapicheck.enabled=false \
  --set resources.requests.cpu=50m \
  --set resources.requests.memory=64Mi \
  --set resources.limits.memory=128Mi \
  --timeout 10m

log "4. Aguardando os pods do cert-manager subirem (pode levar alguns minutos)..."
sleep 30

log "=== Ingress-Nginx e Cert-Manager instalados com sucesso! ==="