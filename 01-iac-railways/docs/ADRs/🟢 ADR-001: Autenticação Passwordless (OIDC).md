Número do ADR: 001<br>
Data: 07-08-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto IaC Multi-Cloud<br>
Status: 🟢 Aceito

## Contexto
O projeto de Infraestrutura como Código (IaC) utiliza quatro provedores de nuvem (AWS, Azure, GCP e Oracle) e duas ferramentas de IaC (Terraform e OpenTofu), cada uma com seu próprio ambiente de execução/backend: Terraform Cloud para ambas as ferramentas neste repositório, e GitHub Actions como orquestrador universal dos pipelines.<br>

O problema central é: como autenticar de forma segura e padronizar múltiplos ambientes de execução de IaC em quatro provedores de nuvem diferente sem depender de credenciais estáticas de longo prazo (Access Keys, Client Secrets, Service Account Keys)?<br>

O uso de chaves estáticas representa riscos significativos de segurança (vazamento de credenciais, rotação manual complexa, "toil" operacional) e não segue as melhores práticas de Zero Trust e segurança moderna em cloud.<br>

## Decisão
Adotar OpenID Connect (OIDC) como padrão universal de autenticação passwordless para todos os ambientes de execução de IaC (Terraform Cloud e GitHub Actions) junto aos quatro provedores de nuvem (AWS, Azure, GCP e Oracle).<br>

A implementação seguirá esta arquitetura: Cada ambiente de execução atuará como Identity Provider (IdP) OIDC, emitindo tokens JWT temporários durante a execução dos jobs de deploy. Nas clouds, configuraremos Trust Policies e Federated Identities que validam esses tokens OIDC e concedem permissões temporárias apenas durante a execução do job:

- **AWS:** IAM Roles com Trust Policies que aceitam tokens OIDC dos três runners.
- **Azure:** Federated Credentials nos App Registrations do Entra ID.
- **GCP:** Workload Identity Pools e Providers mapeando identidades para Service Accounts.
- **Oracle (OCI):** Devido à ausência de suporte nativo a OIDC no TFC, a autenticação ocorre via API Key injetada de forma segura pelo Variable Set do TFC).
 - **Padronização por "Issuer" e "Audience":** A configuração nas clouds será reutilizável, mudando apenas o emissor do token (app.terraform.io, gitlab.com, github.com) e as claims de filtro (repository, branch, environment).Princípio do Menor Privilégio: Cada identidade federada terá permissões restritas e específicas, limitadas ao escopo necessário para o provisionamento da infraestrutura.

## Justificativa
- **Eliminação de Segredos de Longo Prazo:** OIDC elimina completamente a necessidade de armazenar Access Keys, Client Secrets ou chaves de Service Account nos ambientes de CI/CD (GitHub Actions), reduzindo drasticamente a superfície de ataque e o risco de vazamento.
- **Tokens de Curta Duração:** Os tokens JWT emitidos via OIDC têm validade de minutos (tipicamente 5-15 minutos), limitando a janela de exploração em caso de comprometimento.
- **Suporte Nativo das Clouds e Ferramentas:** AWS, Azure e GCP suportam nativamente OIDC com o Terraform Cloud e GitLab CI/CD, sem necessidade de soluções customizadas. Para a Oracle (OCI), devido à complexidade e ausência de suporte transparente via TFC, optou-se por uma exceção arquitetural utilizando API Key injetada de forma segura via Variable Sets do TFC.
- **Governança e Auditoria:** Cada execução de deploy gera logs de auditoria claros nas clouds, mostrando qual identidade federada (qual runner, qual repositório, qual branch) assumiu qual role/permission, facilitando troubleshooting e compliance.
- **Escalabilidade e Manutenção:** A rotação de credenciais é automática e gerenciada pelos provedores de identidade. Não há "toil" operacional de rotacionar chaves a cada 90 dias ou gerenciar múltiplas versões de segredos.

## Alternativas consideradas
**Alternativa 1: Variáveis de ambiente com credenciais estáticas**<br>
Descrição: Armazenar Access Keys, Client Secrets e Service Account Keys nas variáveis de ambiente (CI/CD Variables) de cada ferramenta.<br>

**Por que foi descartada?**<br>
- Alto risco de vazamento (logs, debug, acesso não autorizado às variáveis)
- Necessidade de rotação manual periódica (toil operacional)
- Dificuldade de auditoria (não há vínculo claro entre quem/usou o quê)
- Não segue práticas modernas de segurança em cloud
- Violação potencial de compliance (LGPD, ISO 27001, SOC 2)

**Alternativa 2: HashiCorp Vault dinâmico**<br>
Descrição: Implementar um Vault centralizado para gerar credenciais dinâmicas de curta duração sob demanda.<br>

**Por que foi descartada?**<br>
- Complexidade operacional elevada (manter o Vault HA, backup, disaster recovery)
- Overkill para um projeto de laboratório/portfólio
- Introduz um ponto único de falha (SPOF) adicional
- Curva de aprendizado significativa para configuração e manutenção
- Custo adicional de infraestrutura

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Segurança Fortalecida:** Eliminação completa de credenciais estáticas de longo prazo, reduzindo drasticamente o risco de vazamento e comprometimento. | **Complexidade Inicial de Setup:** Configurar Trust Policies, Federated Credentials e Workload Identity Pools nas quatro clouds exige tempo e conhecimento técnico específico de cada provedor. |
| **Redução de Toil:** Automação completa da rotação de credenciais, eliminando trabalho manual operacional. | **Curva de Aprendizado:** A equipe precisa entender conceitos de OIDC, JWT tokens, claims, audiences e como cada cloud mapeia essas identidades. |
| **Auditoria Aprimorada:** Logs claros e rastreáveis de qual identidade federada executou qual ação em qual cloud, facilitando troubleshooting e compliance. | **Debug Mais Complexo:** Em caso de falha de autenticação, o troubleshooting envolve verificar múltiplas camadas (emissor do token, claims, trust policy, permissões IAM), exigindo familiaridade com logs de auditoria de cada cloud. |
| **Portabilidade:** Capacidade de adicionar novos ambientes de execução (ex: GitLab CI, CircleCI) ou novas clouds com configuração padronizada via OIDC. | **Dependência de Conectividade:** A autenticação OIDC depende de conectividade de rede entre os runners e os provedores de identidade/clouds. Falhas de rede podem impedir o deploy. |
| **Demonstração de Maturidade:** O portfólio demonstra domínio de práticas modernas de segurança (Zero Trust, passwordless, federated identity) altamente valorizadas no mercado. | **Configuração Específica por Runner:** Cada ambiente (Terraform Cloud, GitHub Actions) tem particularidades na configuração do OIDC (URL do emissor, claims disponíveis, audience), exigindo configuração individualizada. |

## Mitigações
- **Documentação Detalhada:** Criar runbooks e diagramas de arquitetura claros para facilitar o onboarding e troubleshooting.
- **Spike Técnico:** Realizar investigação técnica prévia (como feito neste ADR) para validar a viabilidade e mapear as particularidades de cada provedor.
- **IaC para a Própria Segurança:** Usar Terraform/OpenTofu para provisionar as próprias Trust Policies e configurações de OIDC, garantindo versionamento e consistência.
- **Monitoramento e Alertas:** Implementar alertas para falhas de autenticação OIDC, permitindo detecção rápida de problemas de configuração ou conectividade.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 07-08-2026 | Primeira versão  | Documentar a decisão de adotar OIDC para autenticação passwordless multi-cloud | Estabelece padrão de segurança para todo o projeto IaC | Emershow |
