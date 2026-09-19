## 🏛️ O Ministério da Observabilidade
Este laboratório tem como objetivo construir uma plataforma de observabilidade baseada em OpenTelemetry na qual 3 serviços demo são instrumentados uma única vez e têm seus sinais (métricas, logs e traces) roteados para 7 ferramentas sem custo algum de licença: Prometheus, Grafana, Loki e Tempo como stack base contínua no free tier do Grafana Cloud, Elastic auto-hospedado em janelas de experimento, Datadog no plano Free e Dynatrace em trial único.

O objetivo é demonstrar proficiência multi-ferramenta, domínio de diferentes paradigmas de observabilidade (stack OSS gerenciada vs. SaaS all-in-one vs. enterprise com AIOps vs. self-hosted) e práticas de correlação de sinais, governança de dados e otimização de custos desde a concepção — culminando no guia "qual ferramenta para qual cenário" e em um artigo técnico publicável.

---

## 🎯 Princípios e Padrões
Este laboratório opera sob rigorosas boas práticas de engenharia de plataformas:

- **Instrumenta uma vez, avalia tudo:** OpenTelemetry como padrão único — nenhum serviço carrega SDK proprietário, e a troca de backend é configuração no gateway, não código. *(Ver ADR-001)*
- **Comparação justa por construção:** Todas as ferramentas recebem os mesmos dados, da mesma fonte, no mesmo período, julgadas pela mesma ficha de avaliação (scorecard). *(Ver ADR-005)*
- **Janelas de experimento:** A base roda contínua; desafiantes (Elastic, Datadog, Dynatrace) sobem em janelas de tempo limitadas e são desligados ao fim, com evidências exportadas antes. *(Ver ADR-002)*
- **Custo total zero:** Nem licenças, nem infraestrutura — a base vive no free tier do Grafana Cloud, o resto em VMs próprias com Kubernetes leve (k3s).
- **Documentação viva:** Decisões arquiteturais registradas via ADRs, cada uma nascida de pesquisa executada ou de restrição real — duas delas já superseded dentro do próprio planejamento, contando a história de como as decisões evoluíram. *(Ver ADR-008 e ADR-009)*

---

## 📂 Estrutura do repositório
```
paranauelabs/
├── .github/workflows/                   # Orquestração CI (raiz — roteia para o lab correto)
│   ├── tfc-master-pipeline.yml          # Pipeline Mestre do Terraform (Lab 01)
│   ├── tofu-master-pipeline.yml         # Pipeline Mestre do OpenTofu (Lab 01)
│   └── obs-master-pipeline.yml          # Pipeline do Lab 02 (lint de Helm + validação)
├── 01-iac-railways/                     # Laboratório IaC Multi-Cloud
│   └── ...
└── 02-o-ministério-da-observabilidade/  # Este laboratório
    ├── README.md                        # Informações do lab
    ├── docs/
    │   ├── ADR/                         # Architecture Decision Records
    │   ├── arq/                         # Diagramas e imagens de arquitetura
    │   ├── licoes-aprendidas/           # Lições aprendidas
    │   ├── scorecards/                  # As 7 fichas de avaliação das ferramentas
    │   └── game-days/                   # Cadernos e planilhas das simulações de incidente
    ├── helm/                            # Charts: collectors, gateway, demos
    ├── argocd/                          # GitOps — Applications e app-of-apps (entra na R2)
    ├── demos/                           # Serviços A (HTTP), B (mensageria), C (DB+cache)
    ├── grafana/                         # Provisioning JSON do Grafana Cloud
    └── Makefile                         # A "API" do laboratório (cluster, deploy, demo...)
```

---

## ⚙️ Arquitetura do Laboratório
A espinha dorsal é o fan-out: os serviços falam OpenTelemetry para um gateway central, que enriquece, mascara dados sensíveis e roteia os mesmos sinais para todos os destinos ativos — 100% de logs, métricas e traces para a base contínua, e fluxo dedicado para cada desafiante durante sua janela. Trocar de ferramenta nunca toca no código dos serviços.

- **Camada de coleta:** VMs próprias com cluster k3s elástico (1 a 3 nós) — collectors de borda por máquina, gateway central, tudo entregue via Helm.
- **Stack base (contínua):** Endpoint OTLP unificado do Grafana Cloud — métricas caem no Prometheus hospedado, logs no Loki, traces no Tempo, consulta e correlação no Grafana.
- **Ferramentas (janelas):** Elastic sobe na própria VM marcada para experimentos (e desce com um comando); Datadog e Dynatrace recebem os dados via OTLP, como SaaS.
- **Entrega (a partir da R2):** GitOps com ArgoCD — o Git é a única porta de entrada do cluster; rollback é git revert + sync.

---

## 📐 Diagramas de Arquitetura
1. O fan-out de telemetria (o coração do lab)
Uma única instrumentação alimentando todos os destinos ativos:

```
+-----------+     +-------------+     +------------------------+
|  Demos    |     |  OTel       |     |  Gateway Central       |
|  A / B / C| --> |  Collectors | --> |  (enriquecimento,      |
| (3 sinais)|     |  (por nó)   |     |   masking de PII,      |
+-----------+     +-------------+     |   sampling)            |
                                      +----------+-------------+
                                                 |
              100% contínuo                      |  durante janelas
                                                 v
+----------------+  +-----------+  +-----------+  +-----------+  +-----------+
| Grafana Cloud  |  | Elastic   |  | Datadog   |  | Dynatrace |  | ...futuro |
| P + Loki +     |  | (VM,      |  | (SaaS,    |  | (SaaS,    |  | backend   |
| Tempo + Grafana|  |  janela)  |  |  Free)    |  |  trial)   |  |  nº 8     |
+----------------+  +-----------+  +-----------+  +-----------+  +-----------+
        |
        v
+----------------+
|  Consulta e    |
|  correlação    |
|  (métrica ->   |
|  log -> trace) |
+----------------+
```

2. O cluster elástico de VMs
O laboratório funciona com 1 nó e escala até 3 sem redesign — o nó de experimento entra e sai por comando:

```
+-------------------------------+     +-------------------------------+
| VM-1 (k3s server)            |     | VM-2 (k3s agent)             |
| ArgoCD, Gateway, Demo A      |<--->| Demos B e C                   |
+-------------------------------+     +-------------------------------+
        |                    traces cruzando nós de verdade
        v
+-------------------------------+
| VM-3 (agente de onda)         |  taint: wave=elastic
| Elastic — só durante a janela |  entra: make wave-up
| (destruída após o experimento)|  sai:   make wave-down
+-------------------------------+
```

---

## 🔐 Segurança e Governança de Dados
- **Mascaramento de PII no pipeline:** qualquer dado sensível é mascarado no gateway antes de deixar as VMs — vale para todos os destinos, incluindo os SaaS avaliados.
- **Segredos fora do repositório:** API keys vivem em Secrets do Kubernetes; o token do cluster circula apenas por canal seguro.
- **Menor exposição possível:** firewall com apenas SSH inbound; a API do cluster acessível só localmente; egress restrito ao necessário (443).
- **Gasto zero verificável:** free tiers e trial apenas, monitorados desde a primeira semana — nenhuma conversão para plano pago faz parte do desenho.

--

## 🛡️ Decisões Arquiteturais (ADRs)
Decisões técnicas detalhadas na pasta docs/ADR/:

- **ADR-001:** Padrão único de instrumentação (OpenTelemetry)
- **ADR-002:** Stack base contínua + desafiantes em janelas (parcialmente superseded pelo 008)
- **ADR-003:** Grafana como camada unificada e única fonte de alertas
- **ADR-004:** Infraestrutura como código, reproduzível do zero (superseded pelo 009)
- **ADR-005:** Comparação justa por construção
- **ADR-006:** Dynatrace em modo duplo (comparável + diferencial)
- **ADR-007:** Cadastro tardio do trial da Dynatrace
- **ADR-009:** Cluster k3s elástico + Helm + Makefile
- **ADR-008, 010–011:** (nascem das pesquisas da R1 — ver roadmap)

## 🚀 Releases e Roadmap
O projeto é entregue de forma incremental, com 2 fins de semana por release e tags de pré-release até o 1.0.0:

1. **[R1] Coleta OTel, Stack Base e Pilotos Correlacionados (v1.0.0-alpha)** 🔜
    - Spikes de viabilidade (compatibilidade OTLP, auto-instrumentação, limites de free tier) fechados como ADRs.
    - Cluster k3s elástico + gateway OTel com masking e sampling.
    - Stack base no Grafana Cloud e os 3 serviços demo com métricas, logs e traces correlacionados (navegação em ≤ 3 cliques).
2. **[R2] Experimentos Free-Tier, Scorecards e Comparativos (v1.0.0-beta)** 🔜
    - GitOps com ArgoCD — o Git vira a única porta de entrada do cluster.
    - Onda Elastic no nó de experimento + onda Datadog no plano Free.
    - 6 de 7 scorecards preenchidos com decisões documentadas.
3. **[R3] Trial Dynatrace, Gate de Relevância e Evidências (v1.0.0-rc)** 🔜
    - Janela imóvel de ~15 dias: modo comparável (OTLP) + OneAgent em um piloto.
    - Gate de Relevância com 5 experimentos mínimos — descartar com evidência também é entregável.
    - Resposta documentada para "vale pagar pelo SaaS enterprise?".
4. **[R4] Guia de Decisão, Divulgação e Encerramento (v1.0.0)** 🔜
    - Guia "qual ferramenta para qual cenário" + comparativo final das 7.
    - Game day final: tempo até causa-raiz antes vs. depois da correlação.
    - Artigo técnico publicado com o método, os dados e o veredito.