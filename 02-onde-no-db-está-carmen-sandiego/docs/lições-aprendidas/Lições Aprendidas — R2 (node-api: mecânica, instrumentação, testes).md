A R2 é onde o sistema ganhou carne e o processo ganhou dentes — e onde todos os incidentes moraram. As lições de fundação que PREVENIRAM erros estão no documento da R1; aqui está o que aconteceu de verdade.

## 1. Entrega de arquivos — o canal é parte do sistema

**1 — Editar arquivo direto na VM (nano)**<br>
**Erro:** três bugs causados por edição manual na VM, antes de qualquer regra existir.<br>
**Causa:** duas fontes de verdade para o mesmo arquivo — repo e cópia na VM divergem silenciosamente.<br>
**Solução:** regra nº 1 do lab: arquivo nasce no repo, VM recebe por scp, nunca se edita na VM. Nunca mais ocorreu. É também a origem da régua dos nove (firmada na R2.1, válida até a R2.11).<br>

**2 — scp -r sobre árvore existente (franken)**<br>
**Erro:** a collection rodou com 02/03/04 executando o CONTEÚDO do 05 (reset) — gerações misturadas na mesma árvore.<br>
**Causa:** scp -r faz MERGE, não substitui; restos da geração anterior sobrevivem ao lado dos arquivos novos.<br>
**Solução:** rm -rf da pasta antes de cada scp + arquivo entregue sempre COMPLETO (nunca trecho). Árvore franken não tem conserto parcial — só substituição integral.<br>

**3 — Arquivo perdido ou invisível na entrega**<br>
**Erro:** guia.md ausente da árvore (13 arquivos onde o esperado era 14); 02-detalhar chegou sem a extensão .bru — invisível para o CLI, seria pulado em silêncio.<br>
**Causa:** transferência manual de muitos arquivos sem conferência contra um esperado — e o ritual executado DEPOIS do run, quando o dano já estava feito.<br>
**Solução:** ritual ANTES de qualquer run (find contra árvore esperada, contagem de tests por request, URLs por arquivo). E política explícita: docs repo-only (guia, README, .env.example) — o esperado do ritual conhece a exceção (VM: 13 arquivos; repo: 14). Exceção de mirror não documentada é falso alarme de franken esperando hora marcada.<br>

**4 — Diagnosticar a partir de artefato de colagem**<br>
**Erro:** scrollback antigo colado como execução nova; .env apareceu truncado no chat; linha PYTHON_API_PORT duplicada — levou a diagnosticar bug que não existia no arquivo.<br>
**Causa:** cópia/cola entre canais perde, trunca e duplica; o terminal colado não é o estado do arquivo.<br>
**Solução:** antes de diagnosticar, reler o arquivo NA ORIGEM (tail -2 .env, grep no arquivo real). Nenhum fix sai de memória ou de paste.<br>

## 2. Suposição técnica — chute não é fato

**5 — Bodies do contrato chutados**<br>
**Erro:** collection v1 com body de viagem {"cidade": ...} (chave errada — a real é city), mandado por criminalId (modelo errado — o real é pelas 5 características) e Lisboa no ambiente (cidade inexistente na seed).<br>
**Causa:** shape assumido por similaridade com outros projetos, sem ler o que o runtime já provava.<br>
**Solução:** 30 segundos de leitura do smoke-test.sh + curl no /cities derrubaram os três chutes ANTES do commit. Régua: todo assert é FATO (com recibo) ou CHUTE declarado (a validar) — e chute se valida com grep, nunca com run.<br>

**6 — Caminho do id chutado**<br>
**Erro:** captura do case_id voltou vazia (expected '' to match) — a v1 procurava id/numero/caseNumber/case_id; o campo real é case_number (snake_case, como heading_to/revealed_trait/culprit_codename).<br>
**Causa:** navegação por paths prováveis num shape nunca inspecionado — e a cascata de 400s em 02/03/04 ({{case_id}} vazio na URL) mascarava a raiz única.<br>
**Solução:** extração por REGEX no corpo inteiro (CASE-\d{4}-\d{3}), o método que o smoke já provava. Corrigida a raiz, a cascata sumiu sozinha.<br>

**7 — API do Bruno "corrigida" pelo documento errado**<br>
**Erro:** a revisão v2 trocou res.status/res.headers/res.body por getters (res.getStatus()) — teria quebrado TODOS os tests.<br>
**Causa:** documentação de versão nova aplicada a outra linha de CLI; "correção" feita sem prova em runtime.<br>
**Solução:** runtime manda — o run com propriedades passou, a v2 foi revertida e o comportamento ficou registrado no guia: PROPRIEDADES nesta versão. O erro foi meu (assistente), e fica registrado com o mesmo peso dos demais.<br>

**8 — Divergência de versão do CLI**<br>
**Erro:** a linha 1.x do CLI tentou rodar o collection.bru como request (getaddrinfo ENOTFOUND undefined); a latest se comporta diferente dela.<br>
**Causa:** comportamento muda entre linhas de versão — latest flutuante é variação invisível no comando.<br>
**Solução:** versão PINADA: BRUNO_CLI_VERSION=4.2.1 no .env, via build arg (ver R1-3 para o template). A linha que passou 28/28 é a linha que o runner usa — sempre.<br>

**9 — Assert anti-spoiler vacuoso**<br>
**Erro:** o teste anti-spoiler da v1 passava verde — testando o envelope de um 400 (a request nem tinha chegado ao caso).<br>
**Causa:** teste verde em resposta errada: o assert rodou, mas sobre um corpo que não era o alvo.<br>
**Solução:** teste em corpo REAL: culprit_codename não pode existir no detalhe do caso aberto nem no mandado rejeitado — só na resposta de prisão. Teste verde em resposta errada é teste morto.<br>

## 3. Falsos verdes — verde de tabela não é verde de suíte

**10 — PASS com zero requests**<br>
**Erro:** o CLI reportou "✓ PASS" com Requests: 0 — vitória sobre conjunto vazio.<br>
**Causa:** run sem -r escaneou só a raiz (onde não há request) — e um resumo sem contagem esperada parece sucesso.<br>
**Solução:** -r é obrigatório na suíte; e o aceite confere a CONTAGEM esperada (9 requests, 28 tests) contra a tabela — "0/0" é reprovado, não aprovado.<br>

**11 — PASS com conteúdo trocado**<br>
**Erro:** placar 27/27 com três requests executando o conteúdo errado (o reset fantasma em 02/03/04).<br>
**Causa:** o CLI exibe o NOME do arquivo — o CONTEÚDO manda; contagem de arquivos (find) e sintaxe (sh -n) não detectam identidade.<br>
**Solução:** o aceite lê os LABELS dos tests de cada request (pertencem ao request?) + canário estrutural: 04-mandado-errado tem 4 tests — se vier 3, a pasta casos está franken.<br>

**12 — Arquivo invisível quase aprovado**<br>
**Erro:** sem a extensão .bru, o 02-detalhar seria pulado em silêncio — a suíte "passaria" com 8 requests.<br>
**Causa:** a descoberta do CLI é por extensão; arquivo sem extensão não gera erro — gera ausência.<br>
**Solução:** desta vez o ritual rodou ANTES do run e pegou. A ordem do ritual não é burocracia: conferências ANTES, run DEPOIS — invertida, a ordem transforma o detector em atestado de óbito.<br>

## 4. Ferramental — comportamento que morde

**13 — CLI suja os arquivos de ambiente**<br>
**Erro:** após cada run, os .bru de ambiente amanheciam sujos com case_id/cidade_destino — dança de git checkout -- antes de todo commit.<br>
**Causa:** o CLI PERSISTE vars de runtime (setEnvVar) nos arquivos de ambiente da collection.<br>
**Solução:** rodar em cópia descartável: o entrypoint do parity faz cp -r /src /work e executa lá. A árvore do repo nunca é tocada; a dança do checkout acabou.<br>

**14 — CLI baixado a cada execução**<br>
**Erro (de projeto):** cada run com npx re-baixava o CLI (~30s) com versão flutuante.<br>
**Causa:** a conveniência do npx tem custo de rede, tempo e reprodutibilidade.<br>
**Solução:** runner como imagem própria — CLI instalado no build e pinado (R2-8), custo pago uma vez (~2min); runs seguintes caem no cache.<br>

**15 — grep GNU em Alpine**<br>
**Erro:** grep --include='*.bru' — unrecognized option no BusyBox.<br>
**Causa:** hábito GNU; a VM é Alpine e o BusyBox não tem as extensões.<br>
**Solução:** checagens escritas em dialeto BusyBox (find + grep sem --include). A ferramenta de ritual deve rodar onde o ritual roda.<br>

**16 — Aceitação desenhada para ferramenta que não existia**<br>
**Erro:** rota de aceite da collection presumia Bruno desktop + túnel SSH — ambiente que não existe do lado de cá.<br>
**Causa:** assumido o fluxo "canônico" sem confirmar o inventário real (erro meu, assistente).<br>
**Solução:** docker run --network container:<api> — o CLI compartilha a rede da API; 127.0.0.1 dentro do runner É a API. A demo virou serviço no compose (profile parity, DNS node-api:7421); desktop ficou como opcional, nunca dependência.<br>

## 5. Documentação

**17 — Lições aprendidas escritas como relato de conquistas**<br>
**Erro:** a primeira versão do doc de lições saiu narrativa (o que foi construído, o que funcionou) — não o que o formato pede.<br>
**Causa:** confusão entre relatório de fechamento e lição aprendida; lição é incidente, causa e solução — conquista sem incidente não ensina nada.<br>
**Solução:** reescrita integral em erro/causa/solução (e, a seguir, split por release). Meta-lição que se corrige pelo processo que documenta.<br>

**18 — Erros de português nos documentos**<br>
**Erro:** deslises de ortografia e acentuação nos documentos entregues — "régia" por "régua", "valida" por "válida", "conta-las" por "contá-las", "API de pe" por "API de pé" — apontados pelo usuário.<br>
**Causa:** geração focada em conteúdo e estrutura, sem uma revisão de prova dedicada à língua; pressa de entregar não substitui reler.<br>
**Solução:** revisão ortográfica completa antes de toda entrega de documento, e o usuário mantido como revisor final. Em um documento que julga qualidade técnica, erro de língua é erro de qualidade — o leitor não separa um do outro.<br>

## O que as soluções têm em comum

Três padrões atravessam as dezoito lições:

- **Esperado escrito ANTES.** Todo ritual compara contra um esperado que existe antes do run (árvore, contagens, labels). Sem esperado prévio, olho cansado aprova franken.
- **Recibo em runtime.** Fato é o que o terminal devolveu; todo o resto é chute declarado — e chute se resolve com grep de 30 segundos, não com run de 5 minutos.
- **A falha barata é a melhor professora.** Os três falsos verdes (R2-10 a R2-12) ensinaram mais que os nove verdes somados — por isso ocupam capítulo próprio.

## Régua para a R3 (herança imediata)

- Mesmo contrato, mesma seed, mesmos testes: BRUNO_ENVS já é lista — a paridade roda as duas suítes quando python-container existir.
- O smoke valida a python com sh smoke-test.sh http://127.0.0.1:7422 — zero mudança no script.
- PYTHON_API_INTERNAL_PORT já está reservado no .env.
- A régua dos nove vale inteira, sem abatimento. O anti-spoiler tem ADR. A python-api nasce com a régua que a node-api pagou para descobrir.

## Errata nos OUTROS arquivos (o mesmo mal já estava lá)

A auditoria achou os mesmos deslizes em entregas anteriores — todos em comentários/docs, zero impacto em lógica:

| Arquivo | Estava | Correção |
|---------|--------|----------|
| Makefile | "no inicio das receitas" | "no início das receitas" |
| smoke-test.sh | "API de pe (falha amigável...)" | "API de pé (falha amigável...)" |
| smoke-test.sh | "Extracao... (padrao provado...), sed so limpa" | "Extração... (padrão provado...), sed só limpa" |
| smoke-test.sh | "P1..P5 explicitas — zero montagem dinamica" | "explícitas — zero montagem dinâmica" |
| smoke-test.sh | "O dossie devolve... 5 caracteristicas. Despachantamos os colchetes" | "O dossiê devolve... 5 características. Descartamos os colchetes" |
| smoke-test.sh | "caso novo, combinacao qualquer" | "combinação qualquer" |
| bruno/docs/guia.md | "Sem @1: a linha 1.x tenta rodar" | "Nunca use @1: a linha 1.x tenta rodar" |
| README (seção Verificação) | "todos vermelho-quebram" | "em todos, o vermelho quebra (exit code)" |