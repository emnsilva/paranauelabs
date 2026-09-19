Número do ADR: 005<br>
Data: 18-09-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto O Ministério da Observabilidade<br>
Status: 🟢 Aceito

## Contexto
O produto final do laboratório é o guia "qual ferramenta para qual cenário". Se a comparação for enviesada — dados diferentes, períodos diferentes, critérios diferentes — o guia perde o único valor que tem: ser evidência, não opinião.

## Decisão
Toda ferramenta avaliada recebe:

- Os mesmos dados, da mesma pipeline (o gateway);
- No mesmo período de tempo;
- Julgada pela mesma ficha de avaliação (scorecard padronizado: facilidade de configuração, poder de consulta, experiência, alerting, integrações, escalabilidade, custo em escala, comunidade/documentação).

## Justificativa
- **Conclusões defensáveis:** Qualquer leitor do guia consegue checar como a avaliação foi feita.
- **Decisão por evidência:** O objetivo do lab é substituir achismo por dado — e a comparação precisa estar à altura.
- **Reprodutível por terceiros:** O método está documentado, não escondido.

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