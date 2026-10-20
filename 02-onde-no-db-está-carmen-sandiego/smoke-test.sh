#!/bin/sh
# smoke-test.sh — o jogo inteiro de ponta a ponta: abrir, viajar, afunilar,
# mandado certo, mandado errado, reset. R2.11 (formalizado: make smoke).
# Uso: sh smoke-test.sh [base_url]   (default http://127.0.0.1:7421)
set -eu

BASE="${1:-http://127.0.0.1:7421}"
ok()   { printf '[ok] %s\n' "$*"; }
falha(){ printf '[X]  %s\n' "$*" >&2; exit 1; }

CASO_JSON=/tmp/smoke-caso.json
CASO2_JSON=/tmp/smoke-caso2.json
SUSPEITO_JSON=/tmp/smoke-suspeito.json
trap 'rm -f "$CASO_JSON" "$CASO2_JSON" "$SUSPEITO_JSON"' EXIT

# === 0. PRECONDITION — API de pe (falha amigavel em vez de curl misterioso) ===
curl -sf "$BASE/health" > /dev/null || falha "API nao responde em $BASE — suba o ambiente: make full"
ok "api no ar: $BASE"

# === 1. ABRIR O CASO ===
curl -sf -X POST "$BASE/cases" > "$CASO_JSON" || falha "abrir caso"
CASE=$(grep -o 'CASE-[0-9]*-[0-9]*' "$CASO_JSON" | head -1)
[ -n "$CASE" ] || falha "case_number ausente na resposta"
ok "caso aberto: $CASE"

# === 2. AS 4 VIAGENS (seguindo heading_to até a 5a pista) ===
i=1
while [ "$i" -le 4 ]; do
  DESTINO=$(grep -o '"heading_to":"[^"]*"' "$CASO_JSON" | tail -1 | sed 's/.*:"//;s/"//')
  [ "$DESTINO" != "null" ] || falha "heading_to null antes da 5a pista (viagem $i)"
  curl -sf -X POST "$BASE/cases/$CASE/travel" \
    -H 'Content-Type: application/json' \
    -d "{\"city\": \"$DESTINO\"}" > "$CASO_JSON" || falha "viagem $i ($DESTINO)"
  i=$((i + 1))
done
NPISTAS=$(grep -o '"revealed_trait"' "$CASO_JSON" | wc -l | tr -d ' ')
[ "$NPISTAS" = "5" ] || falha "pistas reveladas: $NPISTAS (esperado 5)"
ok "4 viagens, 5 pistas reveladas"

# === 3. AFUNILAR (as 5 pistas como filtros do dossie) ===
# Extracao com grep -o (padrao provado em runtime), sed so limpa o envelope
# e troca ': ' por '|'. P1..P5 explicitas — zero montagem dinamica.
P1=$(grep -o '"revealed_trait":"[^"]*"' "$CASO_JSON" | sed -n 1p | sed 's/"revealed_trait":"//;s/"$//;s/: /|/')
P2=$(grep -o '"revealed_trait":"[^"]*"' "$CASO_JSON" | sed -n 2p | sed 's/"revealed_trait":"//;s/"$//;s/: /|/')
P3=$(grep -o '"revealed_trait":"[^"]*"' "$CASO_JSON" | sed -n 3p | sed 's/"revealed_trait":"//;s/"$//;s/: /|/')
P4=$(grep -o '"revealed_trait":"[^"]*"' "$CASO_JSON" | sed -n 4p | sed 's/"revealed_trait":"//;s/"$//;s/: /|/')
P5=$(grep -o '"revealed_trait":"[^"]*"' "$CASO_JSON" | sed -n 5p | sed 's/"revealed_trait":"//;s/"$//;s/: /|/')

[ -n "$P1" ] && [ -n "$P5" ] || falha "extracao de pistas falhou (P1..P5)"

curl -sf -G "$BASE/criminals" \
  --data-urlencode "${P1%%|*}=${P1#*|}" \
  --data-urlencode "${P2%%|*}=${P2#*|}" \
  --data-urlencode "${P3%%|*}=${P3#*|}" \
  --data-urlencode "${P4%%|*}=${P4#*|}" \
  --data-urlencode "${P5%%|*}=${P5#*|}" \
  > "$SUSPEITO_JSON" || falha "afunilar (request)"

NSUSPEITOS=$(grep -o '"id"' "$SUSPEITO_JSON" | wc -l | tr -d ' ')
[ "$NSUSPEITOS" = "1" ] || falha "afunilar: $NSUSPEITOS suspeitos (esperado 1)"
ok "afunilamento: exatamente 1 suspeito"

# === 4. MANDADO CERTO (as caracteristicas do suspeito unico) ===
# O dossie devolve ARRAY [ {suspeito} ]; o mandado quer OBJETO com as 5
# caracteristicas. Despachantamos os colchetes — o Zod ignora id/codename.
MANDADO=$(sed 's/^\[//;s/\]$//' "$SUSPEITO_JSON")
RESPOSTA=$(curl -sf -X POST "$BASE/cases/$CASE/warrant" \
  -H 'Content-Type: application/json' \
  -d "$MANDADO") || falha "mandado certo (request)"
echo "$RESPOSTA" | grep -q '"status":"solved"' || falha "mandado certo: $RESPOSTA"
CULPADO=$(echo "$RESPOSTA" | grep -o '"culprit_codename":"[^"]*"' | sed 's/.*:"//;s/"//')
ok "PRISAO: $CULPADO"

# === 5. MANDADO ERRADO (caso novo, combinacao qualquer — SEM dica) ===
curl -sf -X POST "$BASE/cases" > "$CASO2_JSON" || falha "abrir caso 2"
CASE2=$(grep -o 'CASE-[0-9]*-[0-9]*' "$CASO2_JSON" | head -1)
RESPOSTA2=$(curl -sf -X POST "$BASE/cases/$CASE2/warrant" \
  -H 'Content-Type: application/json' \
  -d '{"sexo":"fem","hobby":"tenis","cabelo":"ruivo","traco":"anel","veiculo":"limusine"}') \
  || falha "mandado errado (request)"
echo "$RESPOSTA2" | grep -q '"status":"open"' || falha "mandado errado: $RESPOSTA2"
echo "$RESPOSTA2" | grep -q 'rejeitou' || falha "mandado errado sem mensagem do juiz: $RESPOSTA2"
ok "mandado errado: rejeitado SEM dica"

# === 6. RESET ===
RESET=$(curl -sf -X POST "$BASE/api/seed") || falha "reset (request)"
echo "$RESET" | grep -q '"status":"reset"' || falha "reset: $RESET"
ok "reset: $RESET"

printf '\n=== SMOKE VERDE: os 9 endpoints, o jogo inteiro ===\n'