Número do ADR: 006<br>
Data: 12-10-2026<br>
Responsável: Equipe Dev - Projeto Onde no Banco de Dados Está Carmen Sandiego?<br>
Status: 🟢 Aceito

## Contexto
Cada bandido do dossiê precisa de um número de identificação para as URLs (/criminals/5 = ficha do bandido 5). Cada banco resolve isso nativamente do seu jeito: o PostgreSQL tem o SERIAL — uma numeração automática que o banco mantém sozinho (insere a linha, o banco escolhe o próximo número); o MongoDB tem o ObjectId — identificador único gerado na hora, tipo 665f1b2a..., uma string longa e ilegível.

O problema central é duplo: (1) os dois formatos não conversam — se cada lado usasse o seu nativo, as URLs seriam /criminals/5 de um lado e /criminals/665f1b... do outro, quebrando a simetria que o lab promete provar; (2) o spike de ids (atividade 3) revelou uma armadilha no PostgreSQL: depois de carregar o dossiê manualmente, o contador SERIAL não "sabe" que os números 1 a 21 já foram usados — o próximo cadastro colide com id existente e explode em erro de chave duplicada.

## Decisão
Ids inteiros para criminals nas duas stacks:

- **PostgreSQL:** SERIAL nativo.
- **MongoDB:** coleção de contadores — um documento pequeno ({_id: 'criminals', seq: 21}) guardando o último número usado. Para criar um bandido, a API incrementa o contador com uma operação atômica (indivisível — ou acontece inteira ou não acontece; pedidos simultâneos nunca leem o mesmo valor) e usa o número resultante.

Casos (as investigações) seguem regra própria: identificados por case_number legível (CASE-2025-042). Número para o dossiê, que é catálogo; nome para o caso, que é história.<br>

Ressincronização obrigatória ao carregar a seed (o achado central do spike): inserir linhas informando o id manualmente não avança o contador SERIAL. Portanto, todo carregamento da seed termina ressincronizando os geradores:

- **PostgreSQL:** setval('criminals_id_seq', (SELECT MAX(id) FROM criminals), true) — posiciona o contador no último id usado; o próximo será MAX+1. O true final (parâmetro is_called) significa "este valor já foi emitido".
- **MongoDB:** atualiza o documento contador com o mesmo MAX.
- Fonte sempre MAX(id), nunca contagem de linhas — se a numeração um dia tiver buracos, contar linhas daria número errado.
- POST /api/seed reutiliza o mesmo caminho — reset e primeira carga compartilham o código.

## Justificativa
- **Simetria perfeita:** ids inteiros nas duas stacks = mesmas URLs nos dois lados — a comparação de chaves é parte do que se prova.
- **URLs legíveis:** /criminals/5 vs /criminals/665f1b2a... — a primeira é compartilhável, memorizável, documentável.
- **Atomicidade preservada:** o contador com incremento atômico garante, sob pedidos simultâneos, a mesma promessa do SERIAL — números únicos sempre (validado no spike: zero duplicatas sob escritas paralelas).
- **A armadilha documentada:** o comportamento do SERIAL pós-carga manual é o tipo de conhecimento que só se ganha sendo mordido — o ADR transforma a mordida em documentação, poupando o próximo.

## Alternativas consideradas
**Alternativa 1: UUID (identificador universal único) nas duas stacks**<br>
Descrição: gerar ids únicos globais em qualquer linguagem.<br>

**Por que foi descartada?**<br>
- URLs longas e ilegíveis (/criminals/550e8400-e29b-...)
- Sem ordem natural — listagens e debugging perdem a referência
- Perderia o contraste didático SERIAL vs contador (o par de soluções é parte do experimento)

**Alternativa 2: ObjectId puro no MongoDB**<br>
Descrição: usar o identificador nativo do MongoDB.<br>

**Por que foi descartada?**<br>
- Quebra a paridade: chave numérica de um lado, string hexadecimal do outro
- As URLs das duas APIs divergiriam — exatamente o que o contrato proíbe

**Alternativa 3: case_number para tudo**<br>
Descrição: identificadores legíveis em todas as entidades.<br>

**Por que foi descartada?**<br>
- O dossiê é catálogo de referência — pede número curto, estável, ordenável
- case_number é para a entidade volátil (casos), não para o elenco permanente

**Alternativa 4: Contador em memória na aplicação**<br>
Descrição: manter o último id usado na memória do processo.<br>

**Por que foi descartada?**<br>
- Perde o número a cada restart do processo
- Quebra com mais de uma instância rodando (cada uma contaria do seu jeito)

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Chaves simétricas:** as mesmas URLs funcionam nas duas APIs — paridade visível já no primeiro GET. | **Custo no MongoDB:** uma operação extra por cadastro (incrementar contador, depois inserir) — aceito como parte do que se compara. |
| **Reset previsível:** seed carrega, contadores se alinham, próximo cadastro usa o número certo — sempre. | **Etapa obrigatória esquecível:** a ressincronização não quebra build nem teste rápido — quebra o primeiro cadastro real, na hora da demo. |
| **URLs limpas:** número curto e ordenável para o dossiê; case_number narrativo para os casos. | **Contador exposto a operação manual:** alguém mexendo no banco na mão pode desalinhar o contador — o erro aparece longe da causa. |
| **Conhecimento registrado:** a armadilha do SERIAL virou documentação — economiza a próxima vítima. | **Duas técnicas para ensinar:** quem entra no lab precisa entender SERIAL e contador — curva de contexto real. |

## Mitigações
- **Um único caminho de carga por API (ADR-002):** só existe uma função que carrega a seed — usada pelo startup e pelo reset. Não há segunda rota onde a ressincronização poderia ser esquecida.
- **Teste de fumaça pós-reset na suíte (R4):** caso determinístico que faz reset → cria registro de prova → confere o id esperado. Ressincronização quebrada vira vermelho na suíte, não bug na demonstração.
- **Este ADR como documentação da armadilha:** a condição "INSERT manual não avança SERIAL" está explicada aqui — o conhecimento viaja com o repositório.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 12-10-2026 | Primeira versão  | Documentar ids inteiros nas duas stacks e a ressincronização de geradores | Garante chaves simétricas e reset confiável | Emershow |