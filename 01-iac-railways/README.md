## 🚄 IaC Railways
Este laboratório tem como objetivo criar um baseline de infraestrutura como código (IaC) funcionalmente equivalente em uma matriz 2x4: 4 provedores de nuvem (AWS, Azure, GCP e Oracle) provisionados por 2 ferramentas distintas (Terraform e OpenTofu).<br>

O objetivo é demonstrar proficiência multi-cloud, domínio de diferentes paradigmas de IaC (declarativo vs declarativo open-source) e práticas de segurança (Zero Trust, OIDC) e FinOps desde a concepção.

---
## 🎯 Princípios e Padrões
Este laboratório opera sob rigorosas boas práticas de engenharia de plataformas:

- **Zero Trust & Passwordless:** Autenticação entre o GitLab CI/CD e as 4 clouds feita exclusivamente via OIDC. Nenhuma credencial estática é utilizada. (Ver ADR-001)
- **Least Privilege:** As identidades federadas do pipeline possuem escopo restrito aos recursos do laboratório (ex: Compartimentos na OCI, Resource Groups no Azure), contendo o "blast radius". (Ver ADR-002)
- **State Lock Nativo:** O estado da infraestrutura é gerenciado remotamente com bloqueio automático para evitar condições de corrida (Terraform Cloud para HCL, GitLab Managed State para OpenTofu).
- **FinOps desde a concepção:** Todos os recursos possuem tags obrigatórias para rastreamento de custos. O provisionamento de recursos caros (ex: Multi-AZ, Bastion Hosts) é controlado dinamicamente via Feature Flags.
- **Documentação Viva:** Decisões arquiteturais são registradas via ADRs na pasta docs/adr/.


## 📂 Estrutura do repositório
```
paranauelabs/
├── Jenkinsfile                                # Raiz: Roteia para o lab correto
├── .github/                                   # Raiz: Roteia para o lab correto
│   └── workflows/                             # Orquestrador do Lab: Faz os "includes"
│       ├── tfc-pipeline.yml                   # Pipeline Terraform (AWS)
│       └── tofu-pipeline.yml                  # Pipeline OpenTofu (AWS)
├── 01-iac-railways/
│   ├── Jenkinsfile                            # Orquestrador do Lab: Faz os "includes"
│   ├── docs/
│   │   ├── adr/                               # Architecture Decision Records
│   │   └── arq/                               # Diagramas e Imagens
│   ├── terraform/                             # Código HCL (Terraform)
│   │   ├── aws/                               # Baseline AWS
│   │   ├── azure/                             # Baseline Azure
│   │   ├── gcp/                               # Baseline GCP
│   │   └── oci/                               # Baseline Oracle
│   └── opentofu/                              # Código HCL (OpenTofu)
│       ├── aws/                               # Baseline AWS
│       ├── azure/                             # Baseline Azure (Futuro)
│       ├── gcp/                               # Baseline GCP (Futuro)
│       └── oci/                               # Baseline Oracle (Futuro)
└── 02-futuro-lab/
    └── Jenkinsfile                            # Orquestrador do Lab: Faz os "includes"
```

## ⚙️ Arquitetura de CI/CD
A esteira foi desenhada para ser 100% manual (GitOps/GMUD). Ao acionar um workflow no GitHub Actions, você escolhe o Ambiente (dev, staging, prod) e a Ação (deploy ou destroy) via dropdowns.<br>

**Estágios e Comportamento:**

- **Deploy (Validate -> Plan -> Apply):** Roda de forma sequencial e automática assim que o workflow é disparado. O GitHub injeta as Secrets e Variables do Environment selecionado.
- **Destroy:** Roda de forma isolada para destruir a infraestrutura de um ambiente específico (FinOps).

---

## 📐 Diagramas de Arquitetura
1. Fluxo de CI/CD e OIDC (Zero Trust)
Este diagrama demonstra como o GitLab CI/CD se integra ao Terraform Cloud e à AWS sem o uso de credenciais estáticas (100% Passwordless via OIDC).<br>
[CI/CD com Zero Trust](https://gitlab.com/emnsilva/paranauelabs/-/blob/418b84bf8821618c0dd0ae2d219e54928b559450/01-iac-railways/docs/arq/ci-cd.png)

2. Arquitetura de Rede na AWS (Baseline R1)
Este diagrama ilustra o baseline de infraestrutura provisionado na AWS para cada ambiente (Região Primária em sa-east-1).<br>
[R1 Baseline AWS](https://gitlab.com/emnsilva/paranauelabs/-/blob/e8a9c9ae96224b1c4c2be0064fb6e3b925b57f68/01-iac-railways/docs/arq/baselineR1.png)

---

## 🔐 Segurança e FinOps
- Zero Trust: Autenticação 100% passwordless via OIDC entre GitLab, ferramentas de IaC e Clouds (Sem Access Keys).
- Least Privilege: IAM Roles e Policies restritas aos recursos do laboratório (ex: EC2 só acessa o bucket S3 específico).
- FinOps: Tags obrigatórias em 100% dos recursos via default_tags e AWS Budgets configurado com alerta de $5/mês.

---

## 🛡️ Princípios e Decisões Arquiteturais (ADRs)
- **Zero Trust:** Autenticação 100% passwordless via OIDC. Nenhuma credencial estática é utilizada.
- **Least Privilege:** IAM Roles e Policies restritas aos recursos do laboratório.
- **FinOps:** Tags obrigatórias em 100% dos recursos e políticas de desligamento automatizado.
- **Decisões técnicas detalhadas na pasta docs/adr/:**
 - **ADR-001:** Autenticação Passwordless (OIDC)
 - **ADR-002:** IAM e Least Privileges
 - **ADR-003:** Estrutura do Monorepo e Arquitetura de CI/CD
 - **ADR-004:** Arquitetura de Execução e Workspaces no Terraform Cloud
 - **ADR-005:** Backend de Estado para OpenTofu

---

## 🚀 Releases e Roadmap
O projeto é entregue de forma incremental, versionada com Git Tags e Releases no GitLab:

1. [R1] MVP AWS + Terraform (v1.0.0-alpha.1) ✅
 - Configuração inicial do monorepo no GitHub Actions.
 - Autenticação passwordless (OIDC) entre GitHub, TFC e AWS.
 - Provisionamento do baseline AWS (VPC, EC2, S3, IAM) via Terraform. 
2. [R2] Diversificação de Paradigmas (v1.0.0-beta.1) ✅
 - Adaptação do código base para o OpenTofu (fork open-source).
 - Isolamento total de pipelines (Terraform vs OpenTofu) via GitHub Actions.
 - Backend do estado gerenciado pelo Terraform Cloud para ambas as ferramentas.
3. [R3] Expansão Multi-Cloud Declarativa (v1.0.0-beta.2) 🟡 (Em Desenvolvimento)
 - Expansão da matriz para Azure, GCP e Oracle Cloud.
 - Configuração de OIDC para os 3 novos provedores.
 - Provisionamento do baseline de Rede, Compute, Storage e IAM nas 4 clouds.
4. [R4] Matriz Imperativa Multi-Cloud (v1.0.0-beta.3) 🔴 (Não será feito)
 - A Release 4 original, que envolveria Pulumi, foi cancelada e absorvida pela R2/R3 para manter o foco em ferramentas declarativas de alto padrão.
5. [R5] Hardening e Observabilidade (v1.0.0-rc.1) 🔲 (Futuro)
 - Implementação de pipelines agendados de auditoria de drift.
 - Configuração de dashboards de FinOps nativos nas 4 clouds.
 - Finalização de documentações e artigo técnico.
6. [Oficial] Lançamento (v1.0.0) - Projeto 100% concluído e auditável