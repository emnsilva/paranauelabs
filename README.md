## 💡 Paranauê Labs
Bem-vindo ao Paranauê Labs! Este repositório funciona como um centralizador para meus laboratórios de P&D (Pesquisa e Desenvolvimento), provas de conceito (PoCs) e estudos de caso arquiteturais focados em Engenharia de Plataformas, Cloud e DevOps.
O objetivo deste espaço é testar arquiteturas escaláveis, práticas de infraestrutura imutável, segurança (Zero Trust) e automação de ponta a ponta, servindo tanto como ambiente de aprendizado contínuo quanto como portfólio técnico.

## 🎯 Princípios e padrões
Todos os laboratórios hospedados neste repositório seguem um conjunto rígido de boas práticas de engenharia de software:

- **Zero Trust & Passwordless:** Nenhuma credencial estática de longo prazo (Access Keys, Senhas) é utilizada. A autenticação entre esteiras de CI/CD e provedores de nuvem é feita exclusivamente via OIDC (OpenID Connect). (Ver ADR-001)
- **Least Privilege:** Todas as identidades de automação possuem escopo restrito ao ambiente do laboratório, contendo o "blast radius" em caso de falhas. (Ver ADR-002)
- **Infraestrutura como Código (IaC):** Tudo é versionado. Nenhuma infraestrutura é provisionada via console manual.
- **FinOps desde a concepção:** Recursos possuem tags obrigatórias para rastreamento de custos e políticas de desligamento automático para evitar desperdícios.
Documentação Viva: Decisões arquiteturais são registradas via ADRs (Architecture Decision Records) dentro de cada laboratório.

## 📂 Estrutura do repositório
A estrutura de pastas isola cada laboratório para garantir que dependências, código e pipelines não se misturem:
```
paranauelabs/
├── Jenkinsfile                     # Raiz: Roteia para o lab correto
├── 01-iac-railways/
│   └── Jenkinsfile                 # Orquestrador do Lab: Faz os "includes"
└── 02-futuro-lab/
    └── Jenkinsfile                 # Orquestrador do Lab: Faz os "includes"
```

## ⚙️ Estratégia de CI/CD (GitLab)
Para manter a eficiência e o consumo de recursos, o pipeline raiz (Jenkinsfile na raiz deste repositório) atua como um roteador inteligente.
Utilizando condicionais em Groovy para verificar os arquivos alterados no repositório do GitHub (changeset), o pipeline raiz identifica em qual pasta ocorreu um commit. Ele então carrega e executa o Jenkinsfile específico do laboratório afetado. Isso garante que o laboratório "A" não perca tempo rodando testes do laboratório "B".

## 🚀 Laboratórios Disponíveis

1. 🚄 IaC Railways (Multi-Cloud Baseline)
Criação de um baseline de infraestrutura (Rede, Compute, Storage, IAM) funcionalmente equivalente em uma matriz 3x4: 4 provedores de nuvem (AWS, Azure, GCP e Oracle) provisionados por 2 ferramentas distintas (Terraform e OpenTofu).

**Status:** 🟡 Em Desenvolvimento (Fase 1 - MVP AWS)<br>
**Stack:** Terraform Cloud, OpenTofu, GitLab CI/CD, OIDC.
