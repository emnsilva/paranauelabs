Número do ADR: 006<br>
Data: 19-09-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto O Ministério da Observabilidade<br>
Status: 🟢 Aceito

## Contexto
A Dynatrace representa a categoria "enterprise" — e seu diferencial vendido é exatamente o que o protocolo padrão não mostra: o OneAgent (um agente que instrumenta a aplicação sozinho, sem mexer em código) e a análise automática de causa-raiz por IA (Davis). Avaliar a Dynatrace só pelo modo comparável (OTel) seria justo, mas cego: os diferenciais não apareceriam. Avaliar só pelo OneAgent seria o oposto: viesado.

## Decisão
Operar a Dynatrace em dois modos simultâneos durante a janela do trial:

- **Modo comparável:** ingestão via OTel, igual às outras ferramentas (mantém o ADR-005);
- **Modo diferencial:** OneAgent instalado em um único serviço piloto, para avaliar a proposta proprietária — auto-instrumentação sem código e causa-raiz automática.

## Justificativa
- A pergunta central da onda — "vale pagar o preço enterprise?" — só se responde vendo o premium funcionar.
- Isolar o modo diferencial em um piloto contém o efeito: os outros dois serviços seguem idênticos às demais ferramentas.

## Alternativas consideradas
**Alternativa 1: Cada ferramenta no seu "modo ótimo" (agente próprio, fluxo próprio)**<br>
Descrição: Configurar cada ferramenta somente com suas próprias ferramentas e recursos.<br>

**Por que foi descartada?** <br>
Cada fornecedor "brincaria em casa"; o comparativo viraria ranking de marketing, não de evidência.<br>

**Alternativa 2: Anotações informais durante o uso**<br>
Descrição: Cada ferramenta decide o que coletar e enviar.<br>

**Por que foi descartada?**<br>
Sem critérios fixos, a memória escolhe o que lembrar; impossível comparar scorecards entre si.

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Guia com lastro:** Cada conclusão aponta para dado coletado em condições iguais. | **Modo "padrão", não "ideal":** ferramentas avaliadas fora do seu fluxo proprietário (ex.: Datadog recebendo OTel em vez de usar seu agente próprio) — limitação explícita. |
| **Fichas comparáveis entre si:** mesma régua, sete vezes. | **Diferenciais proprietários ficam invisíveis** — exceção estruturada no ADR-006 (modo duplo da Dynatrace). |
| **KR1 mensurável:** o critério de "3 cliques" tem um endereço fixo pra ser auditado.	 | **Configuração duplicada:** o alerting do Grafana convive com o alerting nativo das ferramentas avaliadas (estes, apenas observados). |

## Mitigações
- A limitação do "modo padrão" vai escrita no guia final e no artigo.
- O caso extremo (ferramenta cujo valor está no modo proprietário) tem tratamento dedicado: ADR-006.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 18-09-2026 | Primeira versão  | 	Transcrição da decisão de planejamento |Define o método de avaliação de todo o lab | Emershow |