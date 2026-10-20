# Guia da Collection Bruno — Paridade por Contrato

Lab: Onde no Banco de Dados Está Carmen Sandiego?

Esta é a suíte de aceitação do lab — uma só, de propósito. Ela mora no nível do LAB, não dentro de node-api/, porque a paridade aqui é por HERANÇA, não por cópia: contrato único (OpenAPI + narrativo) e seed única foram congelados na R1, antes de qualquer linha de API, e a python-api da R3 será validada pela MESMA suíte, trocando apenas a base_url. Duas suítes separadas, cada uma aprovando a sua API, é o caminho mais curto para a divergência silenciosa — exatamente o que este lab existe para medir.

Placar de referência: **9 requests, 28 tests**. Esse par é o esperado escrito: todo aceite confere a contagem contra a tabela — nunca só o resumo verde.

## Como rodar

O runner é uma imagem própria: o CLI do Bruno é instalado no build, com a versão vinda do .env (BRUNO_CLI_VERSION=4.2.1, via build arg). O custo do build (~2 min) é pago uma vez e os runs seguintes caem no cache — nada de npx re-baixando CLI com versão flutuante a cada execução.

A demo é um serviço do compose, no profile parity: o runner resolve a API por DNS (node-api:7421), sem túnel e sem porta publicada.

```bash
docker compose --profile parity up --build
```

A rede é o truque que aposentou o túnel SSH: o runner sobe compartilhando a rede do container da API (`docker run --network container:<api>`) — 127.0.0.1 dentro do runner É a API. Bruno desktop ficou como opcional: quem quiser usar, usa; a suíte nunca dependeu dele, e nenhuma rota de aceite pode presumir esse ambiente.

## O -r é obrigatório

Sem `-r`, o CLI escaneia só a raiz — onde não há request — e reporta "✓ PASS" com **Requests: 0**: vitória sobre conjunto vazio. Todo run da suíte usa -r, e o aceite confere a contagem esperada contra a tabela. "0/0" é reprovado, não aprovado.

## O runner roda em cópia descartável

O CLI PERSISTE variáveis de runtime (setEnvVar) nos arquivos de ambiente da collection: case_id, cidade_destino e afins amanhecem sujos no .bru depois de cada run, e a árvore do repo vira uma dança de git checkout -- antes de todo commit. Por isso o entrypoint do parity faz `cp -r /src /work` e executa lá: a árvore do repo nunca é tocada, e o que o CLI suja morre com o container.

## Versão do CLI — pinada, sempre

BRUNO_CLI_VERSION=4.2.1 no .env, via build arg. **Nunca use @1**: a linha 1.x tenta rodar o collection.bru como request (getaddrinfo ENOTFOUND undefined) — e a latest se comporta diferente dela. "Latest" flutuante é variação invisível no comando: o comportamento muda entre linhas de versão sem que nada na tela denuncie. A linha que passou 28/28 é a linha que o runner usa — sempre.

## A API do Bruno nesta versão: PROPRIEDADES

Nesta versão do CLI, a resposta é lida por propriedades: `res.status`, `res.headers`, `res.body`. Os getters da linha nova (res.getStatus() etc.) quebrariam TODOS os tests de uma vez — a documentação oficial descreve a linha nova, mas aqui vale o que o runtime provou na linha pinada: PROPRIEDADES. Este item é registro de incidente: a "correção" pelos getters foi aplicada, revertida pelo run e virou regra neste guia. Runtime manda.

## Ritual — ANTES de qualquer run

1. **Árvore**: find contra a árvore esperada. Repo: 14 arquivos; VM: 13 — docs são repo-only (guia.md, README, .env.example) e o esperado conhece a exceção. Exceção de mirror não documentada é falso alarme de franken esperando hora marcada.
2. **Extensão**: todo request é .bru. Sem extensão, o CLI não gera erro — gera AUSÊNCIA: o arquivo é pulado em silêncio e a suíte "passa" com 8 requests.
3. **Contagens e URLs**: 9 requests, 28 tests, URLs por arquivo — e os labels dos tests pertencem ao request que os carrega.
4. **Canário estrutural**: 04-mandado-errado tem 4 tests. Se vier 3, a pasta casos está franken.
5. **Sintaxe e compose**: sh -n nos scripts e docker compose config --quiet — var faltante estoura alto e cedo, na conferência, nunca em runtime.

A ordem não é burocracia: conferências ANTES, run DEPOIS. Invertida, a ordem transforma o detector em atestado de óbito — o erro aparece depois de consumir o run e a paciência de todo mundo.

## Verde de verdade — o que o aceite confere

- **Contagem contra a tabela**: 9 requests, 28 tests. Resumo sem contagem esperada parece sucesso — "✓ PASS" com Requests: 0 já quase passou.
- **Labels por request**: o CLI exibe o NOME do arquivo, mas o CONTEÚDO manda. Já rodou 27/27 com três requests executando o conteúdo errado (o reset fantasma); contagem de arquivos (find) e sintaxe (sh -n) não detectam identidade — só a leitura dos labels pertencentes ao request.
- **Corpo REAL nos asserts**: verde em resposta errada é teste morto. Um assert pode passar verde sobre o envelope de um 400 que nem chegou ao caso.

## Shape do contrato — onde os chutes morreram

- **case_id**: extração por REGEX no corpo inteiro (`CASE-\d{4}-\d{3}`) — o método que o smoke-test.sh já provava. Navegação por paths prováveis (id, numero, caseNumber) num shape nunca inspecionado devolve vazio em cascata.
- **snake_case é a lei**: case_number, heading_to, revealed_trait, culprit_codename.
- **Viagem**: a chave é `city` — não "cidade".
- **Mandado**: emitido pelas 5 características — não por criminalId.
- **Cidade tem de existir na seed** (12 cidades). Lisboa não existe; chutar cidade por verossimilhança é erro esperando hora marcada.

Trinta segundos de leitura do smoke-test.sh e um curl no /cities derrubam esses chutes ANTES do commit. Chute se valida com grep, nunca com run.

## Anti-spoiler (ADR-003) — requisito funcional

"Quem é o culpado" mora no banco desde o sorteio — qualquer serialização descuidada entrega o jogo. A cadeia foi a decisão escrita virando código: ADR-003 (R1) → serialização própria paraPublico() (R2.5) → assert de corpo real (R2.9).

Na suíte: **culprit_codename não pode existir no detalhe do caso aberto nem no mandado rejeitado — só na resposta de prisão**. E o assert roda sobre o corpo REAL da resposta, nunca sobre envelope de erro.

## Reset e seed — os números são asserts

Todo reset reporta criminals:20 e cities:12 — e a collection confere os dois. Um erro de digitação novo na seed quebra o teste em vez de subir em silêncio: o "limusicleta" da R1 pagou para essa regra existir.

## Entrega de arquivos — o canal é parte do sistema

- **Regra nº 1 do lab**: arquivo nasce no repo, a VM recebe por scp, nunca se edita na VM. Duas fontes de verdade para o mesmo arquivo divergem em silêncio.
- **scp -r faz MERGE, não substituição**: rm -rf da pasta antes de cada scp. Árvore franken não tem conserto parcial — só substituição integral.
- **Arquivo entregue sempre COMPLETO**, nunca trecho.
- **Antes de diagnosticar, reler o arquivo na origem** (tail, grep no arquivo real). O terminal colado não é o estado do arquivo.

## Dialeto da VM (Alpine/BusyBox)

- O grep do BusyBox não tem --include: checagens escritas com find + grep puro. A ferramenta de ritual deve rodar onde o ritual roda.
- Makefile com `.RECIPEPREFIX = >`: TAB não sobrevive a cópia/cola entre canais — o Makefile precisa ser reproduzível de qualquer origem.

## R3 — python-api: a herança imediata

- **BRUNO_ENVS já é lista**: quando o python-container existir, a paridade roda as duas suítes — mesmo contrato, mesma seed, mesmos testes.
- **Smoke**: `sh smoke-test.sh http://127.0.0.1:7422` — zero mudança no script. PYTHON_API_INTERNAL_PORT já está reservado no .env.
- **A régua dos nove vale inteira, sem abatimento.** O anti-spoiler tem ADR. A python-api nasce com a régua que a node-api pagou para descobrir.
