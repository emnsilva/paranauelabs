# 02-o-ministério-da-observabilidade/Makefile
# A "API" do laboratório — cada target é um comando do lab.

SHELL := /bin/bash              # o bootstrap instala o bash (lição nº 1)
.SHELLFLAGS := -eu -o pipefail -c

K8S_SCHEMA ?= 1.31.0            # iguale ao teu k3s: kubectl version

.PHONY: tools lint lint-yaml lint-json lint-helm

## tools: instala/atualiza o kit de ferramentas (qualquer distro)
tools:
    sh scripts/bootstrap-tools.sh

## lint: roda TODA a validação (local e CI usam este mesmo alvo)
lint: lint-yaml lint-json lint-helm
    @echo ""
    @echo "✓ make lint — tudo verde"

## YAML puro (sem templates Go — o kubeconform valida o renderizado)
lint-yaml:
    yamllint .

## JSONs de provisioning do Grafana Cloud
lint-json:
    @files=$$(find grafana -name '*.json'); \
    if [ -n "$$files" ]; then \
        echo "$$files" | while read -r f; do \
            jq empty "$$f" || { echo "✗ JSON inválido: $$f"; exit 1; }; \
        done; \
        echo "✓ JSONs válidos"; \
    else echo "✓ grafana/ sem JSONs ainda"; fi

## Charts Helm: boas práticas + schema do que renderiza
lint-helm:
    @charts=$$(find helm -name Chart.yaml -exec dirname {} \;); \
    if [ -z "$$charts" ]; then echo "✓ helm/ sem charts ainda"; exit 0; fi; \
    echo "$$charts" | while read -r c; do \
        echo "── chart: $$c"; \
        helm lint "$$c" && \
        helm template "$$c" | kubeconform -strict -summary -kubernetes-version $(K8S_SCHEMA) || exit 1; \
    done