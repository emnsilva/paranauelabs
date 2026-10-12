Número do ADR: 001<br>
Data: 12-10-2026<br>
Responsável: Equipe Dev - Projeto Onde no Banco de Dados Está Carmen Sandiego?<br>
Status: 🟢 Aceito

## Contexto
Este laboratório compara duas combinações de tecnologia ("stacks") construindo a mesma API do jogo Carmen Sandiego: a node-api (JavaScript/Node.js + MongoDB, banco de documentos) e a python-api (Python + PostgreSQL, banco relacional). O objetivo final é eleger, com evidência medida, o padrão para as próximas APIs da organização.

O problema central é: como comparar duas stacks de forma justa, se qualquer coisa compartilhada entre elas contaminaria o experimento?

Na engenharia convencional, código duplicado é code smell a eliminar. Aqui, a tentação seria escrever a lógica do jogo uma vez (em uma camada neutra) e "encaixar" as duas stacks em volta — menos código, menos retrabalho. Mas essa economia destruiria exatamente aquilo que o lab existe para observar.

## Decisão
Duplicar o domínio deliberadamente: duas implementações completas e independentes, cada uma escrita da forma canônica (mais natural) do seu mundo — a node-api resolve tudo no paradigma de documentos do MongoDB; a python-api, no paradigma relacional do PostgreSQL.<br>

As duas implementações compartilham apenas dois artefatos, ambos contratos (leis que ambas obedecem), não código:
- O contrato de API (docs/openapi-v1.yaml + documento narrativo): as 9 rotas, formatos, códigos de status e regras da mecânica.
- A seed de dados (data/seed.json): o dossiê da V.I.L.E. (21 bandidos) e as 12 cidades — o ponto de partida idêntico.

Exemplos concretos da divergência proposital:
- **Valores permitidos das pistas:** no PostgreSQL, ENUMs nativos (lista fechada fiscalizada pelo banco); no MongoDB, validação $jsonSchema (regra de schema no documento).
- **Pistas de um caso:** tabela clues com FK e JOIN no PostgreSQL; array itinerary embutido no documento do caso, no MongoDB.
- **Mandado:** tabela 1:1 com UNIQUE de um lado; subdocumento que nasce null do outro.

## Justificativa
- **A duplicação é a variável do experimento:** o lab existe para observar como cada paradigma resolve os mesmos problemas por caminhos próprios. Compartilhar código eliminaria a diferença a observar — como um teste A/B com uma única variante.
- **Contaminação zero:** com implementações independentes, qualquer diferença de comportamento entre as duas APIs só pode ter duas causas — a stack ou um bug. Nunca "o código compartilhado que puxou para um lado".
- **Liberdade canônica:** cada lado usa os recursos naturais do seu banco sem concessões a uma camada comum de tradução.
- **Realismo:** a comparação reflete o que dois times fariam de verdade em duas stacks — o que o relatório final (R5) mede em horas de desenvolvimento é tempo real, não tempo "com cola".

## Alternativas consideradas
**Alternativa 1: Camada de domínio compartilhada (monorepo com pacote comum)**<br>
Descrição: Escrever a lógica do jogo (sorteio, pistas, mandado) uma vez, num pacote neutro; as duas APIs seriam cascas finas de HTTP e persistência.<br>

**Por que foi descartada?**<br>
- Elimina a variável comparada — o experimento perde o objeto de estudo
- Mongoose (MongoDB) e SQLAlchemy (PostgreSQL) são estruturas muito distintas; uni-las exigiria uma camada de tradução que viraria, na prática, uma terceira stack a manter
- O tempo medido deixaria de ser "tempo de construir na stack" e passaria a ser "tempo de manter uma abstração artificial"

**Alternativa 2: Uma única API**<br>
Descrição: Implementar só uma stack e comparar por análise teórica.<br>

**Por que foi descartada?**<br>
- Sem duas implementações não há comparação nem paridade a provar — o lab perde a razão de existir
- Análise teórica é exatamente o "debate sem evidência" que o projeto nasceu para substituir

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Comparação limpa:** qualquer divergência entre as APIs tem causa rastreável (stack ou bug), nunca código misturado. | **Manutenção dupla:** todo bug da lógica do jogo precisa ser corrigido duas vezes, uma em cada stack. |
| **Cada lado canônico:** os recursos nativos de cada paradigma (ENUM vs $jsonSchema, JOIN vs embed) aparecem em todo o seu potencial — matéria-prima do "mapa de paradigma" do relatório. | **Divergência acidental:** dois códigos independentes podem "fazer diferente sem querer" — risco permanente durante toda a implementação. |
| **Medição honesta:** as horas registradas por stack refletem o esforço real de construir em cada uma — dado central da matriz de decisão. | **Custo de mudança dobrado:** qualquer alteração de contrato após o início das implementações custa o dobro (e por isso o congelamento v1 é gate da R1). |
| **Legibilidade didática:** o código espelhado (mesma ordem de seções nas duas) permite comparação lado a lado, seção por seção. | **Escopo estrito:** a duplicação só é viável porque o contrato é finito — 9 endpoints. Um domínio maior tornaria o custo proibitivo. |

## Mitigações
- **Congelamento do contrato:** a janela de mudança fecha antes das implementações começarem — mudança pós-congelamento vira item no backlog v2, com custo explícito antes de ser pago.
- **Código espelhado:** mesma ordem de seções nas duas implementações, para revisão e comparação lado a lado.
- **Suíte de paridade (R4):** divergência acidental vira caso vermelho com número e endereço — rede de segurança contra o risco permanente de "fazer diferente sem querer".

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 12-10-2026 | Primeira versão  | Documentar a decisão de duplicar o domínio intencionalmente | Estabelece a variável central do experimento | Emershow |