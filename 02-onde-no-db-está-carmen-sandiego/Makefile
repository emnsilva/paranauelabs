# paranauelabs / carmen — comandos do laboratório
#
# NOTA: este Makefile usa ">" no inicio das receitas (.RECIPEPREFIX) em vez
# de TAB — decisão deliberada: TAB não sobrevive a copia/cola entre canais,
# e o arquivo precisa ser reproduzível de qualquer origem. GNU make >= 3.82.

.RECIPEPREFIX = >

COMPOSE      = docker compose
COMPOSE_FULL = docker compose -f docker-compose.yml -f api-compose.yml

.PHONY: help up check down reset full parity logs

help: ## lista os comandos
>@awk 'BEGIN {FS = ":.*## "} /^[a-zA-Z_-]+:.*## / {printf "  make %-8s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

up: ## bancos no ar (--wait aguarda healthchecks); cria .env se ausente
>@test -f .env || { cp .env.example .env; echo "== .env criado a partir do .env.example"; }
>$(COMPOSE) up -d --wait

check: ## status + healthy dos dois bancos
>$(COMPOSE) ps
>@$(COMPOSE) ps postgres 2>/dev/null | grep -q healthy && echo "[ok] postgres healthy" || echo "[X] postgres NAO healthy"
>@$(COMPOSE) ps mongo     2>/dev/null | grep -q healthy && echo "[ok] mongo healthy"    || echo "[X] mongo NAO healthy"

down: ## desmonta o ambiente (volumes preservados)
>$(COMPOSE_FULL) --profile full --profile parity down

reset: ## desmonta ZERANDO os dados e sobe de novo
>$(COMPOSE) down -v
>$(COMPOSE) up -d --wait

full: ## bancos + APIs (a partir da R2/R3)
>$(COMPOSE_FULL) --profile full up -d --wait --build

parity: ## suíte de paridade via runner Bruno (R4 — placeholder até lá)
>$(COMPOSE_FULL) --profile full --profile parity up -d --wait

logs: ## acompanha os logs dos bancos
>$(COMPOSE) logs -f