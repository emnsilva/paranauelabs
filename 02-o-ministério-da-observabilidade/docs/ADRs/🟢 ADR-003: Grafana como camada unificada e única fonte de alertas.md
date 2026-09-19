Número do ADR: 003<br>
Data: 18-09-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto O Ministério da Observabilidade<br>
Status: 🟢 Aceito

## Contexto
Sete ferramentas significam sete interfaces — e várias delas emitem alertas por conta própria. Alertas duplicados de fontes diferentes geram fadiga: pessoas param de ler alertas justamente quando eles importam. Além disso, pular entre telas durante uma investigação é exatamente a dor original que o laboratório existe pra combater.

## Decisão
Durante todo o laboratório:

- Grafana é a camada única de consulta e correlação — métricas, logs e rastros navegáveis num só lugar (é o critério do KR1: navegar entre os três sinais em até 3 cliques).
- Alertas saem exclusivamente do Grafana (alerting do próprio Grafana Cloud). As interfaces nativas das ferramentas avaliadas servem para avaliação e registro no scorecard — nunca para disparar alertas do lab.

## Justificativa
- **Elimina duplicação de alertas na origem:** Uma fonte só, sem regra de deduplicação complexa.
- **Experiência consistente:** A investigação de incidente sempre começa no mesmo lugar.
- **Correlação real:** O Grafana conecta os três sinais pelo mesmo identificador de rastro (trace_id).

## Alternativas consideradas
**Alternativa 1: Cada ferramenta alerta por si**<br>
Descrição: Alertas configurados em cada ferramenta avaliada.<br>

**Por que foi descartada?** <br>
- Reproduz a dor que o projeto combate (alertas duplicados). 
- Ferramentas com janelas curtas deixariam buracos no alerting.

**Alternativa 2: Nenhum alerta durante o laboratório**<br>
Descrição: O laboratório não recebe notificações de alerta das ferramentas.<br>

**Por que foi descartada?**<br>
Os game days (simulações de incidente) perdem realismo; alerting é critério de avaliação e precisa existir em algum lugar estável.

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Zero ruído de alerta:** Uma fonte, um canal, uma linguagem. | **Avaliação parcial:** a qualidade de alerting de cada ferramenta fica subavaliada ( elas não alertam) — limitação registrada no scorecard. |
| **Correlação em um lugar:** o fluxo métrica → log → rastro acontece numa tela só. | **Grafana como ponto único de visão:** se ele cai, o lab fica cego momentaneamente (aceitável: é serviço gerenciado com alta disponibilidade). |
| **KR1 mensurável:** o critério de "3 cliques" tem um endereço fixo pra ser auditado.	 | **Configuração duplicada:** o alerting do Grafana convive com o alerting nativo das ferramentas avaliadas (estes, apenas observados). |

## Mitigações
- O scorecard tem campo próprio para a qualidade de alerting de cada ferramenta, avaliado isoladamente.
- A demo comparativa (R2) percorre as interfaces nativas — o que cada ferramenta faria sozinha fica registrado.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 18-09-2026 | Primeira versão  | 	Transcrição da decisão de planejamento | Define a experiência de uso e a política de alertas do lab | Emershow |