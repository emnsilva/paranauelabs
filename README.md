## 🧪 Paranauê Labs
Bem-vindo ao Paranauê Labs! Este repositório funciona como um monorepo centralizador para meus laboratórios de P&D (Pesquisa e Desenvolvimento), provas de conceito (PoCs) e estudos de caso arquiteturais focados em Engenharia de Plataformas, Cloud e DevOps.

O objetivo deste espaço é testar arquiteturas escaláveis, práticas de infraestrutura imutável, segurança (Zero Trust) e automação de ponta a ponta, servindo tanto como ambiente de aprendizado contínuo quanto como portfólio técnico.

---

## 🎯 Princípios e padrões
Todos os laboratórios hospedados neste repositório seguem um conjunto rígido de boas práticas de engenharia de software:

- **Zero Trust & Passwordless:** Nenhuma credencial estática de longo prazo (Access Keys, Senhas) é utilizada. A autenticação entre esteiras de CI/CD e provedores de nuvem é feita exclusivamente via OIDC (OpenID Connect). *(Ver ADR-001)*
- **Least Privilege:** Todas as identidades de automação possuem escopo restrito ao ambiente do laboratório, contendo o "blast radius" em caso de falhas. *(Ver ADR-002)*
- **Infraestrutura como Código (IaC):** Tudo é versionado. Nenhuma infraestrutura é provisionada via console manual.
- **FinOps desde a concepção:** Recursos possuem tags obrigatórias para rastreamento de custos e políticas de desligamento automático para evitar desperdícios.
- **Documentação Viva:** Decisões arquiteturais são registradas via ADRs (Architecture Decision Records) dentro de cada laboratório.

---

## 📂 Estrutura do repositório
A estrutura de pastas isola cada laboratório para garantir que dependências, código e pipelines não se misturem:

```
paranauelabs/
├── .github/                              # Raiz: Roteia para o lab correto
│   └── workflows/                        # Orquestrador do Lab: Faz os "includes"
│       ├── tfc-master-pipeline.yml       # Pipeline Terraform (Multi-Cloud)
│       └── tofu-master-pipeline.yml      # Pipeline OpenTofu (Multi-Cloud)
├── 01-iac-railways/                      # Laboratório IaC Railways
│   ├── docs/
│   │   ├── ADR/                          # Architecture Decision Records
│   │   ├── arq/                          # Diagramas e Imagens de Arquitetura
│   │   └── licoes-aprendidas/            # Documentação de Lições Aprendidas
│   ├── terraform/                        # Código HCL (Terraform)
│   └── opentofu/                         # Código HCL (OpenTofu)
└── 02-futuro-lab/
    └── Jenkinsfile                       # Orquestrador do Lab: Faz os "includes"

```

## ⚙️ Estratégia de CI/CD
A esteira foi desenhada para ser 100% manual (GitOps/GMUD) utilizando workflow_dispatch. Ao acionar um workflow, você escolhe a Cloud, o Ambiente e a Ação via dropdowns. Para manter o DRY, utilizamos Pipelines Mestres que montam o caminho da pasta e injetam as variáveis dinamicamente, permitindo que 2 arquivos de pipeline cubram as 24 combinações da matriz 2x4.

---

## 🚀 Laboratórios Disponíveis
1. **🚄 IaC Railways (Multi-Cloud Baseline)**
Criação de um baseline de infraestrutura (Rede, Compute, Storage, IAM) funcionalmente equivalente em uma matriz 2x4: 4 provedores de nuvem (AWS, Azure, GCP e Oracle) provisionados por 2 ferramentas distintas (Terraform e OpenTofu).

**Status:** ✅ Matriz 2x4 Concluída (R1 a R4) - Pipelines dinâmicos e isolados ativos<br>
**Stack:** Terraform, OpenTofu, GitHub Actions, Terraform Cloud, OIDC.

---

## 👤 Vamos nos conectar!
Conecte-se comigo no [Linkedin](https://www.linkedin.com/in/emnsilva/) e no ✍️ [Medium](https://medium.com/@emershow).