## 🕵️ Onde no Banco de Dados Está Carmen Sandiego?
Este laboratório tem como objetivo recriar o sistema de investigação de Where in the World Is Carmen Sandiego? (Brøderbund, 1985) de forma funcionalmente equivalente em uma matriz 2x2: 2 paradigmas de persistência (PostgreSQL relacional e MongoDB documental) implementados por 2 stacks distintas (FastAPI e Express).

No clássico de 1985, o detetive da ACME cruzava pistas de testemunhas — "a suspeita era ruiva", "ele dirigia um conversível" — no computador da Interpol até sobrar um nome, emitia o mandado e fazia a prisão. O jogo era, no fundo, uma query. Este lab o recria duas vezes — mesma API, mesma mecânica, mesma seed — mudando apenas a stack, para observar lado a lado como o mesmo domínio se traduz em tabelas, ENUMs e JOINs, ou em documentos, arrays embutidos e $jsonSchema.

O objetivo é demonstrar proficiência em polyglot persistence, domínio de diferentes paradigmas de modelagem (normalização vs. desnormalização) e práticas de design de API (contrato único, validação em duas camadas, anti-spoiler) desde a concepção.

|  | python-api | node-api |
| :--- | :--- | :--- |
| Linguagem | Python 3.13 | Node.js 22 LTS|
| Framework | FastAPI | Express 4 |
| Acesso a dados | SQLAlchemy 2.0 + psycopg 3 | Mongoose 8 |
| Banco | PostgreSQL 17 | MongoDB 8 |
| Imagem base | python:3.13-slim | node:22-alpine |

---
## 🎯 Princípios e Padrões
Este laboratório opera sob rigorosas boas práticas de engenharia de APIs:

- **Experimento controlado:** As duas APIs são clones funcionais: mesma seed, mesma spec, mesma mecânica. A duplicação é a variável comparada, não código a ser evitado. (Ver ADR-001)
- **Seed única como fonte da verdade:** O elenco da V.I.L.E. e as cidades nascem de data/seed.json nos dois bancos — comparação justa exige ponto de partida idêntico. (Ver ADR-002)
- **Anti-spoiler como requisito funcional:** Ao abrir um caso, culpado e itinerário completos já estão gravados no banco. É responsabilidade de cada endpoint público responder sem vazar a resposta. (Ver ADR-003)
- **Paridade auditável:** A equivalência entre as duas APIs não é presumida — é provada por testes de contrato contra a mesma spec. (Ver ADR-004)
- **Stacks canônicas:** FastAPI + SQLAlchemy e Express + Mongoose são os pares mais comuns do mercado, para que a comparação reflita o mundo real. (Ver ADR-005)
- **Documentação viva:** Decisões arquiteturais são registradas via ADRs na pasta docs/adr/.


## 📂 Estrutura do repositório
```
paranauelabs/
├── Jenkinsfile                             # Orquestração CI/CD (GitHub Actions)
├── .github/workflows/                      # Orquestração CI/CD (GitHub Actions)
|   ├── carmen-python-api.yml               # Pipeline python-api (lint + testes + build)
|   ├── carmen-node-api.yml                 # Pipeline node-api (lint + testes + build)
│   └── carmen-parity-pipeline.yml          # Testes de contrato (paridade das duas APIs)
├── 01-iac-railways/
|   └── ...                                 # Lab de IaC multi-cloud
├── 02-onde-no-db-está-carmen-sandiego/     # <-- este lab
|   ├── README.md                           # Informações do lab
|   ├── docker-compose.yml                  # Sobe 2 APIs + 2 bancos
|   ├── docs/
|   |   ├── ADRs/                           # Architecture Decision Records
|   |   └── lições-aprendidas/              # Lições aprendidas
|   ├── data/
|   |   └── seed.json                       # Elenco da V.I.L.E. + cidades (fonte única)
|   ├── python-api/                         # A API em FastAPI + SQLAlchemy + PostgreSQL
|   └── node-api/                           # A API em Express + Mongoose + MongoDB
├── 03-futuro-lab/
    └── Jenkinsfile                         # Orquestrador do Lab

```

## 🎮 A Mecânica da Investigação
A mecânica foi desenhada para ser fiel ao original de 1985: cada caso esconde um culpado descrito por 5 características, reveladas uma a cada cidade do itinerário.

Dicionário de pistas — valores fixos, idênticos nos dois bancos:

| Característica | Valores possíveis |
| :--- | :--- |
| Sexo | masculino, feminino |
| Hobby | tênis, música, escalada, skydiving, natação, críquete |
| Cabelo | castanho, loiro, preto, ruivo |
| Traço | manca, anel, joias, tatuagem, cicatriz |
| Veículo |	conversível, limusine, motocicleta, carro de corrida |

Movimentos e comportamento:

- **Abrir o caso (POST /cases):** sorteia o culpado e um itinerário de 5 cidades, grava tudo no banco e devolve a primeira pista — a cena do crime: uma característica revelada e o destino do fugitivo.
- **Viajar (POST /cases/{id}/travel):** acertou a cidade: nova testemunha, nova característica, novo destino. Errou: "as testemunhas não viram nada por aqui" — e o mundo é grande.
- **Afunilar o dossiê (GET /criminals):** os filtros ?sexo=&hobby=&cabelo=&traco=&veiculo= cruzam as pistas coletadas contra o elenco da V.I.L.E.
- **Emitir o mandado (POST /cases/{id}/warrant):** com as 5 características em mãos, o juiz avalia. Acertou: caso resolvido, codinome revelado. Errou: o caso segue aberto — sem dica do que errou, fiel ao original.

Endpoints (idênticos nas duas APIs):

| Método | Rota | O que faz |
| :--- | :--- | :--- |
| GET | /criminals | Dossiê da V.I.L.E., com filtros por característica |
| GET | /criminals/{id} | Ficha de um suspeito |
| GET | /cities | Cidades para onde se pode viajar |
| POST | /cases | Abre um caso novo e devolve a 1ª pista |
| GET |	/cases/{id}	| Detalhe público do caso (só pistas descobertas) |
| POST | /cases/{id}/travel	| Viaja para uma cidade e tenta desbloquear a próxima pista |
| POST | /cases/{id}/warrant | Emite o mandado com as 5 características |

---

## 📐 Diagramas de Arquitetura
1. **A matriz 2x2 (pares isolados)**<br>
Este diagrama demonstra a estrutura do lab: duas APIs independentes, cada uma dona do seu banco. Não conversam entre si e não compartilham nada além da seed.<br>

```
        +---------------------------+        +---------------------------+
        |        python-api         |        |         node-api          |
        |   FastAPI + SQLAlchemy    |        |    Express + Mongoose     |
        +-------------+-------------+        +-------------+-------------+
                      |                                    |
                      v                                    v
        +---------------------------+        +---------------------------+
        |       PostgreSQL 17       |        |         MongoDB 8         |
        |  (paradigma relacional)   |        |  (paradigma documental)   |
        +---------------------------+        +---------------------------+

                  (o detetive: mesmo fluxo nas duas APIs)
```

2. **O mesmo domínio, duas modelagens**<br>
Aqui está o coração do lab: como as mesmas entidades se traduzem em cada paradigma. O que no PostgreSQL vira tabela, FK e ENUM, no MongoDB vira coleção, documento embutido e validação de schema.<br>

```
[ POSTGRESQL: NORMALIZADO ]

countries (id, name)
cities    (id, name, country_id, landmark, loot)
criminals (id, codename, sexo, hobby, cabelo, traco, veiculo)  <- 5 ENUMs
cases     (id, case_number, crime, stolen_item, status,
           culprit_id, opened_at)
clues     (id, case_id, position, city_id, testimony,
           revealed_trait, discovered)
warrants  (id, case_id UNIQUE, sexo, hobby, cabelo, traco,
           veiculo, issued_at)


[ MONGODB: DOCUMENTAL ]

db.criminals { codename, sexo, hobby, cabelo, traco, veiculo }
db.cities    { name, country, landmark, loot }
db.cases     { case_number, crime, stolen_item, status, culprit_id,
               itinerary: [ { city, country, landmark,
                              testimony, revealed_trait, discovered } ],
               warrant: null | { sexo, hobby, cabelo, traco,
                                 veiculo, issued_at } }
```

| Conceito | PostgreSQL | MongoDB |
| :--- | :--- | :--- |
| Pistas de um caso  |  tabela clues + FK/JOIN |  array itinerary embutido
| Ordem das pistas   |  coluna position        |  índice do array
| Mandado (1:1)      |  tabela warrants+UNIQUE |  subdocumento que nasce null
| Valores válidos    |  ENUM nativo            |  validação $jsonSchema
| Ocultar a resposta |  WHERE discovered=true  | projection sem os campos

3. **Fluxo da investigação e o anti-spoiler**<br>
Este diagrama mostra onde a resposta mora — e como ela nunca chega ao detetive antes da hora.

```
POST /cases
  |
  |  sorteia o culpado + itinerário de 5 cidades
  |  grava TUDO no banco (a resposta inclusa)
  v
  +-------------------------------------------+
  | O CASO NO BANCO                           |
  |                                           |
  | culprit_id: 7   <- A RESPOSTA (OCULTA)    |
  |                                           |
  | itinerary[0] Cairo   pista 1  (DESCOBERTA)|
  | itinerary[1] Roma    pista 2  (oculta)    |
  | itinerary[2] Paris   pista 3  (oculta)    |
  | itinerary[3] Tóquio  pista 4  (oculta)    |
  | itinerary[4] Lima    pista 5  (oculta)    |
  +-------------------------------------------+
  |
  |  cada endpoint lê o caso sem vazar a resposta:
  |
  |    GET /cases/{id}    só as pistas descobertas
  |    POST .../travel    cidade certa revela a próxima pista
  |    GET /criminals     os filtros afunilam os suspeitos
  |
  v
  POST /cases/{id}/warrant
    acertou: status "solved" + codinome revelado
    errou:   status "open", sem dica do que errou
```

---

## 🔐 Anti-spoiler e Integridade
- **A resposta mora no banco, não no código:** ao abrir o caso, culpado e itinerário completo já estão persistidos. Nenhum endpoint público retorna culprit_id nem pistas não descobertas — no PostgreSQL via SELECT sem a coluna e filtro discovered; no MongoDB via projection sem os campos.
- **Mandado sem dica:** o juiz rejeita sem dizer o que errou — fiel ao original de 1985. (Modo amigável é uma ideia pós-1.0.)
- **Validação em duas camadas:** borda (Pydantic na python-api, Zod na node-api) e banco (ENUM no PostgreSQL, $jsonSchema no MongoDB) — o dicionário de pistas é garantido dos dois lados, nos dois bancos.
- **Seed idempotente:** cada API popula o banco no startup apenas se ele estiver vazio — sem elenco duplicado nem corrida de seed.

---

## 🛡️ Decisões Arquiteturais (ADRs)
Decisões técnicas detalhadas na pasta docs/adr/:
 - **ADR-001:** Duplicação intencional do domínio (experimento controlado)
 - **ADR-002:** Seed única e carregamento idempotente
 - **ADR-003:** Anti-spoiler — onde a resposta mora e como garantimos que ela não vaza
 - **ADR-004:** Paridade auditável via testes de contrato
 - **ADR-005:** Stacks canônicas de acesso a dados (SQLAlchemy 2.0 e Mongoose)

---

## 🚀 Releases e Roadmap
O projeto é entregue de forma incremental, versionada com Git Tags e Releases no GitHub:

1. **[R1] Fundação: dados e ambientes (v0.1.0-alpha.1)** 🚧
    - Elenco da V.I.L.E. e cidades em data/seed.json (fonte única).
    - docker-compose com 2 APIs + 2 bancos e healthchecks.
    - Schemas dos dois bancos: ENUM vs. $jsonSchema.
2. **[R2] python-api, a implementação de referência (v0.1.0-beta.1)** ⏳
    - FastAPI + SQLAlchemy 2.0 sobre PostgreSQL.
    - Dossiê, casos e mecânica completa de investigação.
3. **[R3] node-api, o espelho documental (v0.1.0-beta.2)** ⏳
    - Express + Mongoose sobre MongoDB.
    - Mesmo contrato, mesma mecânica, modelagem documental.
4. **[R4] Paridade auditável (v1.0.0-rc.1)** ⏳
    - Testes de contrato provando que as duas APIs expõem exatamente a mesma spec.
    - CI no GitHub Actions (lint + testes + build nas duas pipelines).
    - ADRs e lições aprendidas finalizadas.
5. **[Oficial] Lançamento (v1.0.0) — lab 100% jogável e auditável**
6. **Pós-1.0 (ideias):** Terminal do detetive (frontend); modo amigável (mandado errado revela acertos); modo Carmen (prenda todos os capangas para desbloquear o caso da chefa).