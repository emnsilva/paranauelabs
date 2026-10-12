## Contrato da API v1 — Onde no Banco de Dados Está Carmen Sandiego?
#### Status: RASCUNHO — congela na atividade 13 (tag 02-carmen/v0.1.0-alpha.1)
#### Versão: v1 · Especificação canônica: docs/openapi-v1.yaml

## 1. Visão geral e convenções
- **Duas implementações, um contrato:** node-api (Express + Mongoose, porta 7421) e python-api (FastAPI + SQLAlchemy, porta 7422). Todo comportamento descrito aqui é idêntico nas duas — a suíte de paridade (R4) prova.
- **Content-type:** application/json em request e response, exceto onde indicado.
- **Identificadores:** criminals usam id inteiro (URLs /criminals/5); cases usam case_number no formato CASE-YYYY-NNN (ex.: CASE-2025-042).
- **Idioma dos identificadores:** campos e valores de enum sem acento (traco, tenis) — viajam em URLs e query strings, comparados byte a byte. Texto de leitura (nomes, testemunhos) com acento livre.
- Envelope de erro único (seção 5) em toda resposta não-2xx.

## 2. O dicionário de pistas
Cada bandido é descrito por 5 características. Estes são os únicos valores aceitos — validados na borda (Zod/Pydantic) e no banco (ENUM / $jsonSchema):

| Campo | Valores válidos |
| :--- | :--- |
| Sexo | masculino, feminino |
| Hobby | tênis, música, escalada, skydiving, natação, críquete |
| Cabelo | castanho, loiro, preto, ruivo |
| Traço | manca, anel, joias, tatuagem, cicatriz |
| Veículo |	conversível, limusine, motocicleta, carro de corrida |

Valor inválido em qualquer entrada → 400 com detalhe por campo (seção 5). Não existe normalização (Tênis ≠ tenis ≠ TENIS).

## 3. Modelos dos recursos
- Criminal — id (inteiro) · codename (string ≤ 60) · sexo, hobby, cabelo, traco, veiculo (enum, seção 2).
- City — id (inteiro) · name, country, landmark, loot (strings) · country_id nunca exposto (detalhe do modelo relacional).
- Case (visão pública) — case_number · crime · stolen_item · status (open | solved) · clues: array apenas das pistas descobertas · warrant: null ou {sexo, hobby, cabelo, traco, veiculo, issued_at} · wrong_travels (inteiro ≥ 0) · opened_at. Campos que não existem em resposta alguma: culprit_id, pistas futuras, revealed_trait de pista não descoberta (seção 6.4).

## 4. Os 9 endpoints
#### 4.1 GET /health → 200
```
json

{ "status": "ok", "api": "node-api" }
```
Sem depender de banco (disponibilidade do banco é problema do healthcheck do compose, não daqui). Corpo difere de stack apenas no campo api — a suíte ignora esse campo.

#### 4.2 POST /api/seed → 200
Restaura o estado de contrato: elenco e cidades conforme data/seed.json, apaga todos os casos, ressincroniza os geradores de ids (ADR-006: setval(MAX(id), true) / upsert do contador). Corpo:
```
json

{ "status": "reset", "criminals": 20, "cities": 12, "cases_deleted": 3 }
```

#### 4.3 GET /criminals → 200
Dossiê da V.I.L.E. Filtros combináveis, todos opcionais, AND entre eles:
?sexo=&hobby=&cabelo=&traco=&veiculo=
Filtro com valor inválido → 400. Sem filtros: elenco completo (20 registros, sem paginação em v1). Ordenação: id crescente, fixa.

#### 4.4 GET /criminals/{id} → 200 / 404
id inteiro. Não-numérico → 400. Inexistente → 404 com envelope.

#### 4.5 GET /cities → 200
Catálogo de viagem: 12 cidades, ordenadas por id. Sem filtros em v1.

#### 4.6 POST /cases → 201
Abre caso: sorteia culprit (capangas apenas — Carmen, id 1, excluída do sorteio; ela é o caso final do pós-1.0) e itinerário de 5 cidades distintas; grava tudo no banco (a resposta já mora aí — seção 6.4); revela a 1ª pista (a cena do crime: cidade do roubo + 1 característica + direção da fuga). Sem corpo de request. Resposta:
```
json

{
  "case_number": "CASE-2025-042",
  "crime": "Roubou a Máscara de Tutancâmon do Museu Egípcio",
  "stolen_item": "Máscara de Tutancâmon",
  "status": "open",
  "clues": [
    { "city": "Cairo", "testimony": "A suspeita loira embarcou num voo para Roma.",
      "revealed_trait": "cabelo: loiro", "heading_to": "Roma" }
  ],
  "wrong_travels": 0,
  "warrant": null,
  "opened_at": "2025-06-01T12:00:00Z"
}
```

#### 4.7 GET /cases/{case_number} → 200 / 404
O estado público do caso. Caso solved inclui culprit_codename (a revelação pós-vitória). Formato inexistente de case_number → 400.

#### 4.8 POST /cases/{case_number}/travel → 200
Corpo: { "city": "Roma" }. Cidade inexistente no catálogo → 400 (não é 404 — a rota existe, o valor é inválido). Cidade errada (existe, mas não é o próximo destino) → 200 com resposta de testemunha (gameplay, não erro):
```
json

{ "status": "open", "message": "As testemunhas não viram nada por aqui.", "wrong_travels": 2 }
Cidade certa → revela a próxima pista (mesmo formato da 4.6). Certo e errado são ambos 200 — a diferença mora no corpo (clues cresce ou não).
Viagem em caso solved → 409 (seção 5, exceção documentada: recusa de estado, não erro de validação).
Após a 5ª pista revelada, viajar de novo → 200 com { "status": "open", "message": "A trilha acabou. Emissar um mandado.", "wrong_travels": n } — o caso espera mandado, não aceita mais viagem.
```

#### 4.9 POST /cases/{case_number}/warrant → 200
Corpo: as 5 características. Validação idêntica à do dossiê (enum + 400 por campo). Faltando campo → 400.

Tudo bate com o culprit → caso solved, revelação:
```
json

{ "status": "solved", "case_number": "CASE-2025-042", "culprit_codename": "Nick Brunch" }
```
Não bate → 200, caso segue open, sem dizer o que errou (fiel ao original):

```
json

{ "status": "open", "message": "O juiz rejeitou o mandado. Continue investigando." }
```
Mandado em caso solved → 409. Ambos os casos gravam o warrant (o juiz registrou a tentativa) — ele aparece em GET /cases/{id} com as características submetidas.

5. Envelope de erro e tabela de status
Toda resposta 4xx/5xx usa:
```
json

{ "error": "validation_error", "message": "Requisição inválida.", "details": [ { "field": "sexo", "issue": "valor fora do dicionário de pistas" } ] }
error ∈ validation_error · not_found · method_not_allowed · conflict · internal_error.

Situação
Status
Sucesso leitura / ação de gameplay	200
Caso criado	201
Campo inválido/ausente, enum fora do dicionário, formato de id/case_number	400
Recurso inexistente (criminal id, case_number válido e ausente)	404
Verbo não suportado na rota	405
Ação em caso solved (travel/warrant)	409
Erro não tratado	500 (internal_error)
```
Nota de projeto: 409 é a única adição ao card original (que previa 200/201/400/404/405). Ações em caso encerrado são recusa de estado — usar 400 esconderia a diferença entre "requisição ruim" e "caso fechado". Se optares por manter o conjunto estrito do card, 409 → 400 com error: "conflict" — decisão tua antes do congelamento.

## 6. Regras da mecânica
- **6.1 Sorteio —** culprit ∈ criminals com id ≠ 1 (Carmen excluída); itinerário: 5 cidades distintas sorteadas do catálogo; a 1ª é a cena do crime (o crime deriva do loot + landmark dela: "Roubou {loot} de/dO {landmark}"); cada cidade i revela a característica i na ordem fixa sexo → hobby → cabelo → traco → veiculo (a ordem é contrato: a suíte estocástica verifica "pista i revela exatamente a característica i").
- **6.2 Viagem —** a pista i aponta heading_to = cidade i+1. Acertou cidade i+1 → revela pista i+1. Errou → contador wrong_travels incrementa, nada revela, mensagem de testemunha. Não há limite de viagens erradas em v1 (o mundo é grande).
- **6.3 Mandado —** as 5 características contra o culprit gravado. Acerto total → solved + codinome. Parcial → rejeitado sem dica (modo amigável é backlog v2). O warrant fica gravado (última submissão).
- **6.4 Anti-spoiler (requisito funcional I) —** desde o POST /cases, o banco carrega culprit_id e o itinerário completo. Nenhum endpoint público retorna: culprit_id, pistas com discovered = false, heading_to além do revelado, revealed_trait de pista futura. No Postgres: SELECT sem as colunas + WHERE discovered; no Mongo: projection sem os campos. A suíte R4 inclui casos negativos verificando a ausência desses campos em toda resposta de caso.
- **6.5 Seed e reset —** carga idempotente no startup (se vazio); POST /api/seed = reset completo (seção 4.2) com ressincronização de geradores (ADR-006).

## 7. Seed
data/seed.json é a fonte única (ADR-002): 20 capangas + Carmen (id 1, no dossiê, fora do sorteio) + 12 cidades. Regras que o contrato impõe à seed: unicidade das 5-tuplas (mandado = combinação única); identificadores sem acento; ids 1–21 e 1–12 contíguos.

## 8. Access log e x-request-id
Formato idêntico nas duas stacks, um log por request: <timestamp ISO> <method> <path> <status> <duration_ms>. Header x-request-id (UUID v4) em toda response; o terminal do detetive (R4) envia o mesmo x-request-id às duas APIs — mesma jogada, par de traces comparáveis.

## 9. Protocolo de paridade (consumo pela R4)
- **Determinísticos (corpo exato, após normalização):** health (ignorando api), seed, criminals com e sem filtros, criminals/{id} (200 e 404), cities, validações 400 (por campo), 404, 405, formatos de case_number.
- **Estocásticos (schema + invariantes):** POST /cases (case_number válido, 1 pista, 1 característica da ordem 6.1, campos anti-spoiler ausentes); travel certo (pistas crescem exatamente +1, característica da posição correta) e errado (wrong_travels +1, clues inalterado); warrant certo (solved + codinome ∈ dossiê) e errado (open, sem dica); anti-spoiler verificado em todas as respostas de caso.
- **Meta:** ≥ 40 casos, 100% passando nas duas (Outcome 1).

## 10. Exemplos curl
O passeio completo (alternando APIs de propósito) já está no README; a spec OpenAPI carrega os exemplos por endpoint. Os três essenciais:
```
sh

curl -s localhost:7421/health
curl -s "localhost:7422/criminals?cabelo=loiro&sexo=fem"
curl -s -X POST localhost:7422/cases/CASE-2025-042/warrant -H 'Content-Type: application/json' \
  -d '{"sexo":"fem","hobby":"tenis","cabelo":"loiro","traco":"cicatriz","veiculo":"motocicleta"}'
```
Parte 2 — docs/openapi-v1.yaml (spec canônica, esqueleto completo)
```
yaml

openapi: 3.1.0
        status: { type: string, const: ok }
        api: { type: string, enum: [node-api, python-api] }
    SeedResult:
      type: object
      required: [status, criminals, cities, cases_deleted]
      properties:
        status: { type: string, const: reset }
        criminals: { type: integer }
        cities: { type: integer }
        cases_deleted: { type: integer }
    Criminal:
      type: object
      required: [id, codename, sexo, hobby, cabelo, traco, veiculo]
      properties:
        id: { type: integer }
        codename: { type: string }
        sexo: { $ref: "#/components/schemas/Sexo" }
        hobby: { $ref: "#/components/schemas/Hobby" }
        cabelo: { $ref: "#/components/schemas/Cabelo" }
        traco: { $ $ref: "#/components/schemas/Traco" }
        veiculo: { $ref: "#/components/schemas/Veiculo" }
    City:
      type: object
      required: [id, name, country, landmark, loot]
      properties:
        id: { type: integer }
        name: { type: string }
        country: { type: string }
        landmark: { type: string }
        loot: { type: string }
    Clue:
      type: object
      required: [city, testimony, revealed_trait]
      properties:
        city: { type: string }
        testimony: { type: string }
        revealed_trait: { type: string, description: "ex.: cabelo: loiro" }
        heading_to: { type: string }
    Warrant:
      type: object
      properties:
        sexo: { $ref: "#/components/schemas/Sexo" }
        hobby: { $ref: "#/components/schemas/Hobby" }
        cabelo: { $ref: "#/components/schemas/Cabelo" }
        traco: { $ref: "#/components/schemas/Traco" }
        veiculo: { $ref: "#/components/schemas/Veiculo" }
        issued_at: { type: string, format: date-time }
    Case:
      type: object
      required: [case_number, crime, stolen_item, status, clues, wrong_travels, warrant, opened_at]
      properties:
        case_number: { type: string, pattern: "^CASE-[0-9]{4}-[0-9]{3}$" }
        crime: { type: string }
        stolen_item: { type: string }
        status: { type: string, enum: [open, solved] }
        clues:
          type: array
          items: { $ref: "#/components/schemas/Clue" }
        wrong_travels: { type: integer, minimum: 0 }
        warrant: { oneOf: [{ type: "null" }, { $ref: "#/components/schemas/Warrant" }] }
        culprit_codename: { type: string, description: apenas em status solved }
        opened_at: { type: string, format: date-time }
    TravelRequest:
      type: object
      required: [city]
      properties:
        city: { type: string }
    WarrantRequest:
      type: object
      required: [sexo, hobby, cabelo, traco, veiculo]
      properties:
        sexo: { $ref: "#/components/schemas/Sexo" }
        hobby: { $ref: "#/components/schemas/Hobby" }
        cabelo: { $ref: "#/components/schemas/Cabelo" }
        traco: { $ref: "#/components/schemas/Traco" }
        veiculo: { $ref: "#/components/schemas/Veiculo" }
    Error:
      type: object
      required: [error, message, details]
      properties:
        error: { type: string, enum: [validation_error, not_found, method_not_allowed, conflict, internal_error] }
        message: { type: string }
        details:
          type: array
          items:
            type: object
            properties:
              field: { type: string }
              issue: { type: string }
```