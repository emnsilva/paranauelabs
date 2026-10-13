## 🕵️ Onde no Banco de Dados Está Carmen Sandiego?
Este laboratório recria o sistema de investigação de Where in the World Is Carmen Sandiego? (Brøderbund, 1985) de forma funcionalmente equivalente em uma matriz 2x2: 2 paradigmas de persistência (PostgreSQL relacional e MongoDB documental) implementados por 2 stacks distintas (FastAPI e Express).

No clássico de 1985, o detetive da ACME cruzava pistas de testemunhas — "a suspeita era ruiva", "ele dirigia um conversível" — no computador da Interpol até sobrar um nome, emitia o mandado e fazia a prisão. O jogo era, no fundo, uma query. Este lab o recria duas vezes — mesma API, mesma mecânica, mesma seed — mudando apenas a stack, para observar lado a lado como o mesmo domínio se traduz em tabelas, ENUMs e JOINs, ou em documentos, arrays embutidos e $jsonSchema.

O objetivo é demonstrar proficiência em polyglot persistence, domínio de diferentes paradigmas de modelagem (normalização vs. desnormalização) e práticas de design de API (contrato único, validação em duas camadas, anti-spoiler) desde a concepção — e gerar, com evidência medida, o padrão para as próximas APIs da casa.

|  | python-api | node-api |
| :--- | :--- | :--- |
| Linguagem | Python 3.13 | Node.js 22 LTS|
| Framework | FastAPI | Express 4 |
| Acesso a dados | SQLAlchemy 2.0 + psycopg 3 | Mongoose 8 |
| Banco | PostgreSQL 17 | MongoDB 8 |
| Imagem base | python:3.13-slim | node:22-alpine |

As duas APIs são clones funcionais completos (ADR-001): não conversam entre si e não compartilham nada além do contrato e da seed. O teste de tudo isso — o mesmo request disparado contra as duas — roda num terceiro container, o runner de paridade (Bruno CLI), detalhado na R4.

---
## 🎯 Princípios e Padrões
Este laboratório opera sob rigorosas boas práticas de engenharia de APIs:

- **Experimento controlado:** as duas APIs são clones funcionais — mesma seed, mesma spec, mesma mecânica. A duplicação é a variável comparada, não código a ser evitado. (Ver ADR-001)
- **Seed única como fonte da verdade:** o elenco da V.I.L.E. e as cidades nascem de data/seed.json nos dois bancos, carregados de forma idempotente pelas próprias APIs — comparação justa exige ponto de partida idêntico. (Ver ADR-002)
- **Anti-spoiler como requisito funcional:** ao abrir um caso, culpado e itinerário completos já estão gravados no banco. É responsabilidade de cada endpoint público responder sem vazar a resposta — e da suíte verificar a ausência. (Ver ADR-003)
- **Paridade auditável:** a equivalência entre as duas APIs não é presumida — é provada por testes de contrato, divididos entre casos determinísticos (corpo exato) e estocásticos (schema + invariantes). (Ver ADR-004)
- **Stacks canônicas e pino por lockfile:** FastAPI + SQLAlchemy e Express + Mongoose são os pares mais comuns do mercado; versões exatas via lockfile commitado, para que a comparação reflita o mundo real — de forma reprodutível. (Ver ADR-005)
- **Ids inteiros nas duas stacks:** chaves numéricas em criminals (SERIAL de um lado, contador atômico do outro) mantêm as URLs idênticas; o carregamento da seed sempre ressincroniza os geradores. (Ver ADR-006)
- **Documentação viva:** decisões arquiteturais são registradas via ADRs na pasta docs/adr/ (padrão da casa: contexto, decisão, justificativa, alternativas, consequências e mitigações), e lições aprendidas em docs/licoes-aprendidas/.


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

Sem Jenkinsfile por decisão registrada: CI do paranauelabs é GitHub Actions; a dupla Jenkins × Actions já foi demonstrada no [01-iac-railways](../01-iac-railways/). Cada lab varia a sua variável — aqui, a variável é stack, não orquestrador.

---

## 🎮 A Mecânica da Investigação

A mecânica foi desenhada para ser fiel ao original de 1985: cada caso esconde um culpado descrito por 5 características, reveladas uma a cada cidade do itinerário.

**Dicionário de pistas** — valores fixos, idênticos nos dois bancos. Os *identificadores* (o que viaja em URLs e query params) são sem acento; a leitura, com acento:

| Característica | Valores (identificador) |
| :--- | :--- |
| sexo | `masc`, `fem` |
| hobby | `tenis`, `musica`, `escalada`, `skydiving`, `natacao`, `cricket` |
| cabelo | `castanho`, `loiro`, `preto`, `ruivo` |
| traco | `manca`, `anel`, `joias`, `tatuagem`, `cicatriz` |
| veiculo | `conversivel`, `limusine`, `motocicleta`, `carro de corrida` |

Em português, para o detetive: sexo masculino/feminino; hobby tênis, música, escalada, skydiving, natação, críquete; cabelo castanho, loiro, preto, ruivo; traço manca, anel, joias, tatuagem, cicatriz; veículo conversível, limusine, motocicleta, carro de corrida.

**Movimentos e comportamento:**

- **Abrir o caso (`POST /cases`):** sorteia o culpado (entre os capangas — a Carmen, id 1, é a chefa e não é sorteável em v1) e um itinerário de 5 cidades, grava tudo no banco e devolve a primeira pista — a cena do crime: uma característica revelada e o destino do fugitivo.
- **Viajar (`POST /cases/{case_number}/travel`):** acertou a cidade: nova testemunha, nova característica, novo destino. Errou: "as testemunhas não viram nada por aqui" — e o mundo é grande.
- **Afunilar o dossiê (`GET /criminals`):** os filtros `?sexo=&hobby=&cabelo=&traco=&veiculo=` cruzam as pistas coletadas contra o elenco da V.I.L.E.
- **Emitir o mandado (`POST /cases/{case_number}/warrant`):** com as 5 características em mãos, o juiz avalia. Acertou: caso resolvido, codinome revelado. Errou: o caso segue aberto — **sem dica do que errou**, fiel ao original.

**Endpoints (idênticos nas duas APIs — detalhes na spec canônica `docs/openapi-v1.yaml`):**

| Método | Rota | O que faz |
| :--- | :--- | :--- |
| GET | `/health` | Disponibilidade da API |
| POST | `/api/seed` | Reset: restaura o estado de contrato e ressincroniza ids |
| GET | `/criminals` | Dossiê da V.I.L.E., com filtros por característica |
| GET | `/criminals/{id}` | Ficha de um suspeito |
| GET | `/cities` | Cidades para onde se pode viajar |
| POST | `/cases` | Abre um caso novo e devolve a 1ª pista |
| GET | `/cases/{case_number}` | Detalhe público do caso (só pistas descobertas) |
| POST | `/cases/{case_number}/travel` | Viaja para uma cidade e tenta desbloquear a próxima pista |
| POST | `/cases/{case_number}/warrant` | Emite o mandado com as 5 características |

Convenções de status: 200 sucesso · 201 caso criado · 400 validação (detalhe por campo) · 404 inexistente · 405 verbo não suportado · 409 ação em caso já resolvido.

---

## 📐 Diagramas de Arquitetura

**1. A matriz 2x2 (pares isolados):**<br>
Duas APIs independentes, cada uma dona do seu banco — e o runner de paridade, o terceiro ator que prova a equivalência:

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

        +---------------------------+
        |      runner (R4)          |  dispara o MESMO request contra as
        |  Bruno CLI em container   |  duas e compara as respostas
        +---------------------------+
```

2. **O mesmo domínio, duas modelagens**<br>
O coração do lab: como as mesmas entidades se traduzem em cada paradigma.<br>

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
| Pistas de um caso | tabela `clues` + FK/JOIN | array `itinerary` embutido |
| Ordem das pistas | coluna `position` | índice do array |
| Mandado (1:1) | tabela `warrants` + UNIQUE | subdocumento que nasce `null` |
| Valores válidos | ENUM nativo | validação `$jsonSchema` |
| Ids inteiros | SERIAL | coleção `counters` com incremento atômico |
| Ocultar a resposta | SELECT sem as colunas + `WHERE discovered` | projection sem os campos |

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

- **A resposta mora no banco, não no código:** ao abrir o caso, culpado e itinerário completo já estão persistidos. Nenhum endpoint público retorna `culprit_id` nem pistas não descobertas — no PostgreSQL via SELECT sem as colunas e filtro `discovered`; no MongoDB via projection sem os campos.
- **Mandado sem dica:** o juiz rejeita sem dizer o que errou — fiel ao original de 1985. (Modo amigável é ideia pós-1.0.)
- **Validação em duas camadas:** borda (Pydantic na python-api, Zod na node-api) e banco (ENUM no PostgreSQL, `$jsonSchema` no MongoDB) — o dicionário de pistas é garantido dos dois lados, nos dois bancos.
- **Seed idempotente:** cada API popula o banco no startup apenas se ele estiver vazio — sem elenco duplicado nem corrida de seed. O `POST /api/seed` repete o mesmo caminho de código (reset determinístico).

---

## 🚀 Como rodar

**Fluxo local (com Docker instalado):**

```
bash
make up        # bootstrap do .env (se ausente) + bancos no ar + healthchecks
make check     # status + healthy dos dois bancos
make full      # APIs + bancos (quando as R2/R3 existirem)
make down      # desmonta (volumes preservados)
make reset     # desmonta ZERANDO os dados (o botão de reset do lab)
```

**Fluxo VM (o laboratório de reprodutibilidade):** o lab foi validado em 4 distros (Alpine, Debian, CentOS, RHEL) — o sweep de reprodutibilidade do Requisito D. A VM só sustenta containers: tudo (runtimes, APIs, bancos, runner) vive em imagem.

```
sudo sh scripts/installparanaue.sh   # deps + docker + esqueleto do lab
# scp dos arquivos do lab para dentro da estrutura
make up
```

O par installparanaue/uninstallparanaue monta e desmonta a máquina de forma idempotente e verificável — o uninstall é o botão de reset da VM inteira. (Ubuntu: fora do sweep por decisão documentada — autenticação ssh+sudo exige interação indisponível no fluxo de comando; reaberto se virar requisito.)

Testando de fora da VM: as portas são publicadas em 127.0.0.1 (postura de segurança do lab) — o acesso externo sancionado é o túnel SSH:

```
Host vm-alpine
  HostName <ip-da-vm>
  User <usuario>
  LocalForward 7421 127.0.0.1:7421    # node-api
  LocalForward 7422 127.0.0.1:7422    # python-api
```

**Aí, na sua máquina:** as APIs "existem" em localhost:7421/7422 — o Bruno desktop (testes manuais) funciona direto. As collections .bru são arquivos versionados no repo: a mesma collection roda no desktop (via túnel) e no runner em container (make parity, na rede interna do lab). Bruno não tem versão web — desktop para o humano, CLI em container para a máquina.

---

## 🧪 Validação do ambiente
O roteiro oficial de verificação (usado no aceite da R1 e reutilizável a qualquer momento) — tudo via docker compose exec, sem cliente

| Cenário | Comando | Esperado | O que prova |
| :--- | :--- | :--- | :--- |
| A — restart	| docker compose restart | registro de teste presente | dados sobrevivem a reinício de processo |
| B — recriação	| down + up -d | registro de teste presente | volume sobrevive à recriação dos containers |
| C — reset	| down -v + up -d | registro de teste ausente | o caminho de reset funciona (pré-requisito do POST /api/seed) |

```
# gravar um registro de teste (estrutura efêmera, prefixo __)
docker compose exec postgres psql -U acme -d carmen \
  -c "CREATE TABLE __teste_persistencia (ok int); INSERT INTO __teste_persistencia VALUES (1);"
docker compose exec mongo mongosh carmen --quiet --eval 'db.__teste_persistencia.insertOne({ok: 1})'

# verificar (após cada cenário)
docker compose exec postgres psql -U acme -d carmen -c "SELECT * FROM __teste_persistencia;"
docker compose exec mongo mongosh carmen --quiet --eval 'db.__teste_persistencia.countDocuments()'

# limpar
docker compose exec postgres psql -U acme -d carmen -c "DROP TABLE __teste_persistencia;"
docker compose exec mongo mongosh carmen --quiet --eval 'db.__teste_persistencia.drop()'
```

---

## 🛡️ Decisões Arquiteturais (ADRs)
Decisões técnicas detalhadas na pasta docs/adr/:
 - **ADR-001:** Duplicação intencional do domínio
 - **ADR-002:** Seed única e carga idempotente
 - **ADR-003:** Anti-spoiler como requisito funcional
 - **ADR-004:** Paridade auditável por testes de contrato
 - **ADR-005:** Stacks canônicas e pino por lockfile
 - **ADR-006:** Ids inteiros e ressincronização de geradores

---

O projeto é entregue de forma incremental, versionado com Git Tags e Releases no GitHub (tags prefixadas por lab no repositório):

1. **[R1] Contrato, ambiente e matriz de decisão (02-carmen/v0.1.0-alpha.1)** 🚧
    - Contrato v1 congelado (OpenAPI canônica + narrativo): 9 endpoints, envelope de erro, dicionário de pistas, regras da mecânica, anti-spoiler.
    - data/seed.json congelada como contrato de dados.
    - Infra: docker-compose (bancos) + compose.apis.yaml (APIs + runner), Makefile, .env.example.
    - Prep de máquina validado em 4 distros (Alpine, Debian, CentOS, RHEL) — install/uninstall idempotentes.
    - Spikes: sanidade das stacks (ADR-005) e estratégia de ids (ADR-006).
    - Matriz de decisão com pesos e desempate, aprovada com stakeholders.
2. **[R2] node-api, a implementação de referência (v0.1.0-beta.1)** ⏳
    - Express + Mongoose sobre MongoDB — a stack de referência primeiro; o custo de aprendizado da segunda vira dado do relatório.
    - Dossiê, casos e mecânica completa; collection .bru nasce junto.
3. **[R3] python-api, o espelho relacional (v0.1.0-beta.2)** ⏳
    - FastAPI + SQLAlchemy 2.0 sobre PostgreSQL, em paridade de contrato.
    - Re-sweep das VMs com make full.
4. **[R4] Suíte de paridade e terminal do detetive (v1.0.0-rc.1)** ⏳
    - ≥ 40 casos de teste (determinísticos + estocásticos), runner Bruno em container, um comando, relatório pass/fail.
    - Terminal do detetive: página que dispara a mesma jogada nas duas APIs, lado a lado, com latências e mesmo request-id.
    - CI no GitHub Actions (pipelines por API + parity-pipeline).
5. **[Oficial] Lançamento (v1.0.0) — lab 100% jogável e auditável; ADRs e lições aprendidas finalizadas.**
6. **Pós-1.0 (ideias):** modo amigável (mandado errado revela acertos); modo Carmen (prenda todos os capangas para desbloquear o caso da chefa); frontend completo; DELETE no contrato; CORS/auth para uso real.

---

📜 Créditos
Where in the World Is Carmen Sandiego? foi criado por Gene Portwood e Lauren Elliott e lançado pela Brøderbund em 1985. Este é um projeto educacional, sem fins comerciais; Carmen Sandiego é marca registrada de seus detentores.