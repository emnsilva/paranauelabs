Número do ADR: 001<br>
Data: 18-09-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto O Ministério da Observabilidade<br>
Status: 🟢 Aceito

## Contexto
O laboratório avalia 7 ferramentas de observabilidade (Prometheus, Grafana, Loki, Tempo, Elastic, Datadog e Dynatrace). Cada uma delas tem seu próprio jeito de "se plugar" às aplicações: bibliotecas e agentes específicos que o desenvolvedor instala dentro do código para coletar métricas, logs e rastros de execução (traces).

O problema central: se os 3 serviços do lab forem conectados à ferramenta X usando a biblioteca da própria X, então trocar de ferramenta — ou avaliar uma sétima ao lado da primeira — significa reescrever código de aplicação, sete vezes. Além do retrabalho, isso cria dependência permanente do fornecedor: a famosa "amarrão" (vendor lock-in).

## Decisão
Adotar OpenTelemetry (OTel) como padrão único e obrigatório de instrumentação. OTel é um padrão aberto, mantido pela mesma fundação do Kubernetes, que funciona como o "idioma comum" da telemetria: os serviços falam OTel, e uma camada intermediária (o gateway) traduz para o formato que cada ferramenta entende.<br>

**Regras práticas:**<br>
- Nenhum serviço do lab carrega biblioteca proprietária de fornecedor.
- Toda telemetria nasce em OTel; a adaptação para cada ferramenta acontece no gateway, nunca no código da aplicação.
- **Exceção controlada:** O OneAgent da Dynatrace, em um único serviço, durante a janela do trial (ADR-006).

## Justificativa
- Instrumenta uma vez, avalia tudo: o mesmo dado alimenta as 7 ferramentas, presentes e futuras.
- **Sem amarração:** Trocar de ferramenta vira mudança de configuração no gateway, não mudança de código.
- **Padrão consolidado da indústria:** Adotado até pelos próprios fornecedores avaliados aqui.
- **Base da comparação justa:** Se todos recebem o mesmo dado do mesmo pipeline, o comparativo tem valor (ADR-005).

## Alternativas consideradas
**Alternativa 1: Biblioteca proprietária de cada ferramenta**<br>
Descrição: instrumentar os serviços com o SDK oficial de cada fornecedor avaliado.<br>

**Por que foi descartada?**<br>
- Retrabalho multiplicado por 7 (instrumentar, testar, desfazer, repetir).
- Amarração permanente ao fornecedor escolhido.
- Comparação injusta: cada ferramenta veria dados coletados do seu próprio jeito.
- Custo de manutenção alto num projeto de executor único.

**Alternativa 2: Não padronizar nada**<br>
Descrição: deixar que cada ferramenta se conecte como preferir, sem padrão central.<br>

**Por que foi descartada?**<br>
- Inviável de operar com recursos limitados (cada fluxo é um sistema pra manter).
- Telemetria inconsistente entre ferramentas invalida o comparativo.
- Aprenderia-se 7 fluxos, e não 1 padrão transferível.

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Portabilidade total:** adicionar um oitavo backend no futuro é apontar o gateway pra ele. | **Camada extra:** conceitos do OTel (formatos, contexto, coletor) precisam ser aprendidos antes da primeira entrega. |
| **Comparação justa por construção:** todos bebem da mesma fonte, no mesmo formato. | **Recursos proprietários não chegam:** algumas funcionalidades exclusivas (ex.: auto-descoberta do OneAgent) não aparecem via OTel — tratado como exceção no ADR-006. |
| **Um só ponto de configuração:** decisões de roteamento, mascaramento e filtragem vivem no gateway. | **Pequeno custo de processamento:** uma tradução a mais no caminho do dado (medida no requisito de overhead ≤ 5%). |

## Mitigações
- O gateway concentra toda a adaptação — mudança de ferramenta nunca toca na aplicação.
- Exceções ao padrão exigem ADR próprio (é o caso do 006).
- "Paved road" (variáveis de ambiente prontas) reduz o esforço de instrumentar um serviço novo a minutos.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 18-09-2026 | Primeira versão  | Transcrição da decisão de planejamento | Define o alicerce de todo o laboratório | Emershow |
