## 🚦 BlueGreen Co.
Este laboratório tem como objetivo dominar **blue/green deployment** na prática: duas versões da mesma aplicação (blue e green) convivendo no cluster, um `Rollout` que alterna 100% do tráfego após análise automática de métricas, validação de saúde antes do corte, rollback em segundos sem redeploy e um teste de carga que roda **durante** a promoção para provar o zero downtime.

O objetivo é internalizar a mecânica de releases sem downtime — o usuário final nunca pode sentir um deploy — e as práticas que sustentam o padrão: gates de saúde explícitos, lado antigo nunca destruído, caos controlado para treinar o rollback e a mesma automação reproduzível a partir de um `make lab-up`, em qualquer máquina.

---

## 🎯 Princípios e Padrões
Este laboratório opera sob práticas rígidas de release engineering:

- **Análise antes do switch:** nenhum lado recebe tráfego público antes de o `AnalysisTemplate` consultar o Prometheus por taxa de erro e latência p95 durante alguns minutos. Métrica ruim = promoção abortada, produção intocada.
- **Rollback quente:** o lado antigo **nunca é destruído** após o switch. Rollback não é redeploy — é reverter o `Service` ativo, em segundos, porque o lado anterior esteve no ar o tempo todo.
- **Zero downtime é teste, não promessa:** o `k6` martela requests durante a promoção e publica o relatório no repositório — no terminal e no log do Argo Rollouts. É critério de aceite, não slide de marketing.
- **GitOps como fonte única:** nenhuma mudança chega ao cluster por `kubectl apply` avulso. Tudo passa pelo Git e é reconciliado pelo Argo CD. Auditoria e reprodutibilidade por construção.
- **Uma imagem, duas versões:** o mesmo código atende os dois lados; identidade vem de variáveis de ambiente (`APP_COLOR`, `APP_VERSION`, `APP_FAIL_MODE`). Constrói-se uma vez, etiqueta-se duas.
- **Local = CI:** o que roda no seu `make lab-up` é o mesmo conjunto de manifests que o Argo CD reconcilia no cluster; o mesmo Dockerfile que o GitHub Actions constrói. Nenhum caminho paralelo de deploy.
- **Fail-safe por construção:** qualquer falha mantém o tráfego no lado original — o erro máximo do lab é "nada aconteceu".
- **Documentação viva:** decisões arquiteturais registradas em ADRs (`docs/adr/`), pesquisa em tutoriais (`docs/tutoriais/`), retrospectivas em `docs/licoes-aprendidas/`.

---

## 📂 Estrutura do repositório

```
paranauelabs/
├── .github/workflows/
│   └── blue-green-lab.yml         # Pipeline CI/CD do lab (pytest + deploy em minikube efêmero)
└── 02-bluegreen-co/
    ├── README.md                  # narrativa + diagramas Mermaid/ASCII + custo + "o que faria diferente"
    ├── Makefile
    ├── .gitignore
    ├── docs/
    │   ├── adr/
    │   │   ├── 0001-so-das-vms-alpine.md
    │   │   ├── 0002-k3s-em-vez-de-kubeadm.md
    │   │   ├── 0003-gitops-fonte-unica.md
    │   │   ├── 0004-argo-rollouts-bluegreen.md
    │   │   └── 0005-alocacoes-estaticas-e-ksm.md
    │   ├── licoes-aprendidas/
    │   │   └── 2026-11-XX-r1.md
    │   └── tutoriais/
    │       ├── provisionamento-do-lab.md
    │       ├── runbook-operacao.md
    │       └── alpine-k3s-compatibilidade.md
    ├── infra/
    │   ├── README.md
    │   ├── scripts/
    │   │   ├── provision-vms.sh
    │   │   ├── prepare-kernel.sh
    │   │   ├── install-k3s.sh
    │   │   ├── enable-ksm.sh
    │   │   └── lib/common.sh
    │   ├── cloud-init/
    │   │   ├── user-data.tpl
    │   │   ├── meta-data.tpl
    │   │   └── network-config.tpl
    │   └── inventory/
    │       └── hosts.yml.example
    ├── cluster/
    │   ├── bootstrap/argocd/
    │   ├── apps/
    │   │   ├── root-app.yaml
    │   │   └── children/
    │   ├── bluegreen/
    │   └── observability/grafana/dashboards/
    ├── app/
    │   ├── Dockerfile
    │   ├── requirements.txt
    │   ├── bgapp/
    │   ├── migrations/
    │   └── tests/
    ├── experiments/
    │   ├── 01-zero-downtime/
    │   ├── 02-analysis-block/
    │   ├── 03-rollback/
    │   ├── 04-expand-contract/
    │   └── 05-postmortem/
    ├── scripts/
    │   ├── demo-promotion.sh
    │   ├── check-health.sh
    │   └── setup-dev.sh
    └── logs/                          # gitignored
```


---

## ⚙️ Arquitetura de CI/CD

A esteira é **GitOps de ponta a ponta**. O GitHub Actions constrói a imagem e atualiza a tag no repositório de manifests; o Argo CD reconcilia o cluster; o Argo Rollouts conduz a promoção. Nenhum `kubectl apply` manual em produção.

**Estágios e Comportamento:**

- **Tests (pytest):** suíte unitária da aplicação roda primeiro. Falhou? A imagem nem é construída — primeiro portão.
- **Build + Push:** imagem publicada no GHCR com tag semântica; `trivy` verifica vulnerabilidades antes do push.
- **Commit de tag:** workflow atualiza `cluster/bluegreen/rollout.yaml` com a nova tag, assinado. O Argo CD detecta e sincroniza.
- **Promoção:** o Argo Rollouts cria o `ReplicaSet` green, executa o `prePromotionAnalysis` (consulta Prometheus), e só então troca o `Service` ativo.
- **Evidência:** o relatório do `k6` é commitado em `experiments/01-zero-downtime/results/`.

**Acionamento:** manual (workflow_dispatch com dropdown de tag) ou push para `main` quando algo muda em `02-bluegreen-co/app/**`. O Argo CD sincroniza de forma automática após o commit de tag — mas a **promoção** aguarda aprovação manual (`autoPromotionEnabled: false`) ou análise automática, conforme configuração do `Rollout`.

**Migração para cluster real (EKS/GKE/AKS):** o mesmo `cluster/` funciona sem alteração. Basta apontar o Argo CD para um cluster gerenciado — os manifests, o `Rollout` e o `AnalysisTemplate` não mudam.

---

## ▶️ Como executar

| Ferramenta | Versão sugerida | Para quê |
|---|---|---|
| `virt-manager` + `libvirtd` | 4+ | hospedar as 3 VMs Alpine |
| `kubectl` | 1.30+ | interação com o cluster k3s |
| `helm` | 3.14+ | instalação do Argo CD e stack |
| `k6` | 0.50+ | teste de carga durante a promoção |
| `curl` | qualquer | smoke tests e status |

```
bash
make lab-up                                       # 1. cria as 3 VMs, instala k3s, sobe Argo CD
make bootstrap-gitops                             # 2. instala ingress, cert-manager, stack de observabilidade
kubectl argo rollouts get rollout bgapp --watch   # 3. acompanha promoções em tempo real

make demo-promotion                               # 4. promove a próxima versão com k6 rodando em background
make check-health                                 # 5. consulta /health e /version de ambos os slots

kubectl argo rollouts undo bgapp                  # 6. rollback em segundos

```

Primeiro acesso (a partir do host, com as VMs no ar):
```
curl -ik https://bgapp.local/                     # certificado self-signed, headers X-Environment/X-Version
kubectl get svc bgapp-active -n bluegreen \
  -o jsonpath='{.spec.selector.slot}'              # qual slot está ativo AGORA
```

---
## 📐 Diagramas de Arquitetura

1. **Topologia: VMs, cluster e slots**<br>
Três VMs Alpine hospedam um cluster k3s. Sobre ele, o Argo CD reconcilia o estado declarado no Git; o Argo Rollouts conduz a promoção blue/green usando Prometheus como árbitro da saúde.

```
┌─────────────────────────────────────────────────────────────────────┐
│ NOTEBOOK (host) — KVM/virt-manager · KSM habilitado                 │
│                                                                     │
│  ┌────────────────────┐  ┌────────────────────┐  ┌────────────────┐ │
│  │ VM1 · control      │  │ VM2 · worker       │  │ VM3 · worker   │ │
│  │ Alpine · 2 GB      │  │ Alpine · 3 GB      │  │ Alpine · 3 GB  │ │
│  │                    │  │                    │  │                │ │
│  │ k3s server         │  │ k3s agent          │  │ k3s agent      │ │
│  │ Argo CD            │  │ Prometheus         │  │ Grafana        │ │
│  │ Argo Rollouts      │  │ CloudNativePG      │  │ ingress-nginx  │ │
│  │ cert-manager       │  │ (PostgreSQL)       │  │ bgapp BLUE     │ │
│  │                    │  │ bgapp GREEN        │  │                │ │
│  └─────────┬──────────┘  └─────────┬──────────┘  └───────┬────────┘ │
│            └───────────────────────┴─────────────────────┘          │
│                        rede interna do cluster k3s                  │
└─────────────────────────────────────────────────────────────────────┘
```

2. **Fluxo de tráfego e o switch**<br>
O Service ativo aponta para um slot por vez. O Argo Rollouts decide qual slot recebe o tráfego após a análise do Prometheus — não há patch manual:

```
                          clientes (curl / k6)
                                │
                    ┌───────────▼────────────┐
                    │     ingress-nginx      │──── cert-manager (TLS)
                    └───────────┬────────────┘
                                │
                    ┌───────────▼────────────┐
                    │ Service bgapp-active   │
                    │ selector: slot=blue    │◄── Argo Rollouts
                    └────┬──────────────┬────┘    (único que troca)
                         │ 100%         │ 0%
                         ▼              ▼
                   ┌──────────┐   ┌──────────┐
                   │ BLUE v1  │   │ GREEN v2 │
                   │ 2 pods   │   │ 2 pods   │
                   └────┬─────┘   └────┬─────┘
                        └──────┬───────┘
                               ▼
                     ┌───────────────────┐
                     │ PostgreSQL (CNPG) │
                     │ schema expand     │
                     └─────────┬─────────┘
                               ▼
                     ┌───────────────────┐
                     │ Prometheus        │
                     └─────────┬─────────┘
                               │ consulta (erro + p95)
                               ▼
                     ┌───────────────────┐
                     │ AnalysisTemplate  │
                     └───────────────────┘
```

3. **Sequência de promoção**<br>
Seis fases controladas pelo Argo Rollouts, com dois gates de segurança (análise e janela de rollback):

```
[1] commit da nova tag no repositório de manifests
       │
       ▼
[2] Argo CD detecta o diff ──► sync (cria GREEN, sem tráfego)
       │
       ▼
[3] Readiness probe do GREEN ──► está pronto?
       │
       ├── não ──────────► [ABORTA] BLUE segue 100%
       │ sim
       ▼
[4] prePromotionAnalysis ──► consulta Prometheus
       │
       ├── falhou ───────► [ABORTA] BLUE segue 100%
       │ passou
       ▼
[5] Argo Rollouts troca Service active: blue ──► green
       │
       ▼
[6] k6 valida durante a janela de segurança
       │
       ├── 5xx ──────────► [rollback em segundos]
       │ ok
       ▼
[7] GREEN promovido definitivamente; BLUE fica ocioso (alvo de rollback)
```

## 🧪 Experimentos

Os cinco experimentos abaixo são o lab em si — cada um prova um ganho com dados, não com slides.

**Experimento 1 — Zero downtime provado:** k6 com 200 VUs rodando durante a promoção. O relatório comprova zero requisições 5xx durante a troca:

```
========== RELATÓRIO K6 — PROMOÇÃO BLUE → GREEN ==========
  URL alvo         : https://bgapp.local/
  duração          : 300s
  VUs máx          : 200
  total requests   : 49.417
    acertos blue   : 27.884
    acertos green  : 21.533
    falhas (5xx)   : 0
  latência p95     : 187ms (blue) → 179ms (green)
  troca detectada  : 1 (blue → green no request #27.885)
=========================================================
[ ok ] ZERO DOWNTIME comprovado — 49.417 requests, 0 falhas.
```

2. **Experimento 2 — Análise barra promoção defeituosa:** injetar degradação no green ocioso (make chaos-on COLOR=green) e disparar a promoção. O AnalysisTemplate reprova no gate e aborta — a versão ruim nunca chega ao usuário. Acompanhar com kubectl argo rollouts get rollout bgapp --watch mostrando o estado Degraded.
3. **Experimento 3 — Rollback em menos de 60 segundos:** com o green ativo, kubectl argo rollouts undo bgapp. Cronometrar do comando até curl retornar X-Version: 1.0.0 (blue). Evidência em captura com timestamp.
4. **Experimento 4 — Migração expand/contract com as duas versões no ar:** demonstrar que um schema adicionado em formato expand funciona para blue (v1) e green (v2) simultaneamente. Só depois da promoção definitiva, a coluna antiga é removida (contract). Sem isso, o rollback quebraria o banco.
5. **Experimento 5 — Postmortem de uma promoção que falhou:** documentar um experimento que não funcionou como esperado durante o desenvolvimento — com causa raiz, linha do tempo, ação corretiva e lição. Publicado em experiments/05-postmortem/README.md.

---
## 🔐 Segurança e Operação
- **Superfície mínima:** imagem base python:3.12-alpine3.24 (16 pacotes na base, pin por digest), conforme ADR 0001. Scan trivy roda no CI em cada build.
- **Caos controlado:** APP_FAIL_MODE derruba /health e / do lado escolhido sem tocar no código — o rollback é treinado de verdade, não imaginado.
- **Sem credenciais na aplicação:** a aplicação não usa segredos. O workflow roda com permissions: contents: read, packages: write e não requer nenhum secret para o lab local. O GHCR usa o GITHUB_TOKEN do próprio runner.
- **Probes nativos como última linha de defesa:** readiness/liveness do Kubernetes — pod doente sai do Service sozinho, independentemente do Rollout.
- **Auditoria por headers:** toda response assinada com X-Environment, X-Version, X-Pod — saber quem atendeu cada request é um curl -i de distância.
- **KSM com trade-off documentado:** o host usa Kernel Samepage Merging para reduzir consumo agregado. Trade-off de canal lateral por timing é aceito no lab (cargas próprias confiáveis) e registrado no ADR 0005.

---
## 🛡️ Decisões Arquiteturais (ADRs)
Decisões técnicas em docs/adr/:
- **ADR-001:** Imagem base do `bgapp` — Alpine 3.24 com pin por digest (🟢 Aceito; implementação pendente)
- **ADR 002:** k3s em vez de kubeadm (🟢 Aceito)
- **ADR 003:** GitOps como fonte única via Argo CD (🟢 Aceito)
- **ADR 004:** Argo Rollouts para blue/green com análise de métricas (🟢 Aceito)
- **ADR 005:** Alocações estáticas de memória e KSM (🟢 Aceito)

---
## 🚀 Releases e Roadmap
O projeto é entregue de forma incremental, com Tags e Releases no GitHub. Toda a linha pertence ao alvo v1.0.0 (convenção registrada no ADR 003).

1. **[R1] Provisionar infraestrutura · v1.0.0-alpha.1** ✅
    - 3 VMs Alpine 3.24.2 + k3s v1.36.x, integração com OpenRC
    - Scripts de provisionamento, make lab-up / lab-down
    - POP de provisionamento em docs/tutoriais/
2. **[R2] Instalar base GitOps · v1.0.0-alpha.2**
    - Argo CD no modelo app-of-apps, ingress-nginx, cert-manager
    - ResourceQuota e LimitRange por namespace
3. **[R3] Publicar aplicação v1 em produção · v1.0.0-beta.1**
    - bgapp expondo /version, /health, /debug/degrade
    - CloudNativePG + primeira migração expand
    - TLS self-signed via cert-manager
4. **[R4] Automatizar pipeline de CI · v1.0.0-beta.2**
    - GitHub Actions: pytest → build → push GHCR → commit de tag
    - trivy no pipeline e proteção de branch
5. **[R5] Implementar blue/green com Argo Rollouts · v1.0.0-rc.1**
    - Rollout blueGreen + AnalysisTemplate consultando Prometheus
    - prePromotionAnalysis barrando promoções degradadas
    - Dashboards Grafana e runbook de operação
    - Execução dos 5 experimentos com evidências versionadas