# Número do ADR: 004
**Data:** 06-11-2026
**Responsável:** Equipe SRE/DevOps - Lab BlueGreen Co.
**Status:** 🟢 Aceito

## Contexto
O coração do laboratório é demonstrar o padrão **Blue/Green**. Este padrão exige que a nova versão (Green) suba ao lado da versão atual (Blue) e que o tráfego seja chaveado somente após a validação da saúde do Green. 

O `Deployment` nativo do Kubernetes não foi feito para isso. Ele faz *Rolling Update* (substitui pods aos poucos) e não permite a troca imediata de tráfego entre dois ambientes isolados. Além disso, a decisão de promover a versão Green não pode ser baseada apenas em *readiness probes* (que dizem apenas "o pod subiu"), mas sim em métricas de negócio (taxa de erro, latência) obtidas no monitoramento.

O problema central é: **como automatizar a troca de tráfego baseada em métricas reais, garantindo rollback automático em caso de degradação?**

## Decisão
Adotar o **Argo Rollouts** como controlador de deploy, substituindo o `Deployment` padrão pelo CRD `Rollout` (estratégia `blueGreen`).

A implementação seguirá este desenho:
- **Análise Pré-Promoção:** O `Rollout` criará o `ReplicaSet` Green e executará um `AnalysisTemplate` que consulta o Prometheus (taxa de erro HTTP 5xx e latência p95) por um período definido.
- **Troca Condicional:** O `Service` ativo só será chaveado para o Green se a análise passar. Caso contrário, a promoção é abortada automaticamente.
- **Janela de Rollback:** O lado Blue permanecerá no ar (sem tráfego) por uma janela de segurança, permitindo rollback instantâneo via CLI (`kubectl argo rollouts undo`).

## Justificativa
- **Validação Real:** O gate de promoção não depende de "achismo". O Prometheus é o árbitro da saúde da aplicação.
- **Rollback Automatizado:** Se a versão nova degradar as métricas, o usuário final nunca é exposto.
- **Integração com o Ecossistema:** Já utilizamos o Argo CD para o GitOps. O Argo Rollouts compartilha a mesma filosofia declarativa e se integra perfeitamente à stack.
- **Dashboards Visuais:** A CLI e a integração com o Grafana permitem visualizar a promoção passo a passo.

## Alternativas consideradas

### Alternativa 1: `kubectl patch` manual no Service
**Descrição:** Manter dois `Deployments` (blue e green) e usar um script que valida a saúde via `curl` e, se der certo, altera o seletor do `Service`.
**Por que foi descartada?**
- **Falta de Inteligência:** A validação via `curl` é binária (200 OK ou não) e não avalia métricas agregadas (latência, taxa de erro sob carga).
- **Sem Rollback Automático:** Se a versão quebrar após o switch, a reversão depende de intervenção humana executando o script novamente.

### Alternativa 2: Flagger
**Descrição:** Ferramenta GitOps de *Progressive Delivery* que também suporta Blue/Green e Canary.
**Por que foi descartada?**
- O Flagger exige a adoção do Flux CD (já descartado no ADR-003). Introduzir duas ferramentas GitOps concorrentes (Argo CD e Flux) no mesmo laboratório adicionaria complexidade desnecessária.

## Consequências

| POSITIVAS | NEGATIVAS/DESAFIOS |
|---|---|
| **Deploy seguro:** Nenhuma versão com erro é promovida sem passar pelas métricas do Prometheus. | **Dependência de Observabilidade:** Exige que o Prometheus esteja instalado e coletando métricas corretamente antes do primeiro deploy. |
| **Rollback em segundos:** A volta para o Blue é feita em um comando, pois o ambiente antigo permanece intacto. | **Complexidade de Manifests:** O `AnalysisTemplate` exige a escrita de queries PromQL (ex: `sum(rate(http_requests_total{status=~"5.."}[2m]))`). |
| **Visibilidade:** O status da promoção é visível via `kubectl argo rollouts get rollout`. | **Overhead de CRDs:** Adiciona novos Custom Resource Definitions ao cluster (Rollout, AnalysisTemplate, ClusterAnalysisTemplate). |

## Mitigações
- **Dependência do Prometheus:** A R5 foi planejada para ocorrer após a instalação da stack de observabilidade. O `AnalysisTemplate` terá limites de tolerância (`failureLimit`) para não falhar por dados transitórios de warm-up.
- **Complexidade de Queries:** As queries PromQL serão versionadas no repositório e testadas isoladamente antes de serem anexadas ao `AnalysisTemplate`.
- **Recursos do Cluster:** O Argo Rollouts possui pegada leve (~100 MB de RAM). A cota do namespace `bluegreen` foi dimensionada para suportar o controlador e os pods da aplicação.

## Registro de Mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por |
|---|---|---|---|---|
| 06-11-2026 | Primeira versão | Documentar a decisão de adotar Argo Rollouts para o padrão Blue/Green com análise de métricas. | Substitui o Deployment padrão, garantindo validação antes da troca de tráfego e rollback automatizado. | Emershow |