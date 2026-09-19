Número do ADR: 002<br>
Data: 18-09-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto O Ministério da Observabilidade<br>
Status: 🟡 Parcialmente substituído — a base migrou para o Grafana Cloud (ADR-008); as janelas de tempo permanecem válidas

## Contexto
Sete ferramentas, recursos limitados (VMs próprias) e um executor único. Rodar tudo ao mesmo tempo estoura a memória disponível — e pior: cada ferramenta acumularia dados de períodos diferentes, tornando o comparativo enviesado.

## Decisão
Dividir as ferramentas em duas categorias:

- **Base contínua (Prometheus, Grafana, Loki, Tempo):** Roda o tempo todo — é o chão do laboratório e a linha de referência permanente.
- **Ferramentas (Elastic, Datadog, Dynatrace):** Sobem apenas durante janelas de tempo limitadas (2–4 semanas; a Dynatrace, os ~15 dias do trial) e são desligados ao fim, com tudo que precisa ser preservado exportado antes.

## Justificativa
1. Pico de recursos controlado: no máximo uma ferramenta por vez ao lado da base.
2. Avaliações de ida única: trials e períodos de teste não voltam — janelas são o formato natural deles.
3. Continuidade da referência: a base sempre no ar dá estabilidade pra medir evolução (KR3).

## Alternativas consideradas
**Alternativa 1: Rodar as 7 simultaneamente**<br>
Descrição: tudo rodando o tempo todo, avaliação em paralelo contínuo.<br>

**Por que foi descartada?**<br>
- Estoura a memória das VMs; multiplica pontos de falha; dados de períodos diferentes invalidam a comparação.

**Alternativa 2: Revezar todos, inclusive a base**<br>
Descrição: uma ferramenta por vez, sem stack de referência permanente.<br>

**Por que foi descartada?**<br>
Perde a linha de referência contínua; o KR1 (correlação dos pilotos) exige a base sempre disponível; trocar o chão do lab toda semana é operacionalmente cruel.

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Memória previsível:** O pico é sempre "base + 1". | **Dados das ferramentas morrem com a janela:** Exportação obrigatória antes do desligamento. |
| **Foco de avaliação:** Uma ferramenta por vez, com atenção total do executor. | **Históricos assimétricos:** A base acumula semanas; a ferramenta, dias — limitação registrada nas fichas de avaliação. |
| **Saída limpa:** Desligar um desafiante não afeta o restante do lab. | **Disciplina de calendário:** janelas precisam ser respeitadas, senão o plano desanda. |

## Mitigações
- Exportação de evidências com prazo interno antes do fim de cada janela (dia 10, no caso da Dynatrace).
- O formato "janela" está refletido no plano de releases (R2 e R3 são as janelas).
- Scorecards registram o período coberto por cada ferramenta.


## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 18-09-2026 | Primeira versão  | Transcrição da decisão de planejamento | Define o formato de operação do lab | Emershow |
| 18-09-2026 | Status: parcialmente substituído  | Decisão de mover a base para o Grafana Cloud gratuito |A base deixa de ocupar as VMs; janelas seguem válidas | Emershow |