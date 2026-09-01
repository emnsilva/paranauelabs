Número do ADR: 002<br>
Data: 07-08-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto IaC Multi-Cloud<br>
Status: 🟢 Aceito

## Contexto
O ADR-001 definiu a autenticação via OIDC (AuthN), permitindo que os pipelines de IaC (GitHub Actions e Terraform Cloud) se conectem às clouds (AWS, Azure, GCP e Oracle) sem usar credenciais estáticas.<br>

O problema agora é a Autorização (AuthZ): Quais permissões exatas essas identidades federadas devem ter?<br>

Conceder permissões administrativas completas (ex: AdministratorAccess na AWS, Owner no Azure/GCP/OCI) para o pipeline de IaC viola o princípio do menor privilégio (Least Privilege). Em caso de comprometimento do repositório, vazamento do token OIDC ou um erro catastrófico no código (ex: um terraform destroy acidental), o "blast radius" (raio de explosão) seria ilimitado, podendo afetar toda a organização.

## Decisão
Adotar o princípio de Menor Privilégio e Contenção de Blast Radius para todas as identidades federadas dos pipelines de IaC, utilizando as seguintes estratégias nativas de cada provedor:

- **AWS:** Criação de IAM Roles com Policies customizadas restritas por Tags ou ARNs específicos dos recursos do laboratório. Implementação de Explicit Deny (negação explícita) para ações críticas: alterar o CloudTrail, modificar as próprias Trust Policies do OIDC, criar novos usuários IAM e acessar o Billing.
- **Azure:** Uso do papel nativo "Contributor" restrito estritamente ao escopo do Resource Group do laboratório. A identidade federada não terá nenhuma atribuição no nível de Subscription ou Management Group.
- **GCP:** Uso de papéis predefinidos granulares (ex: roles/compute.admin, roles/storage.admin, roles/network.admin) aplicados com IAM Conditions para restringir o acesso apenas ao Projeto e aos recursos específicos do laboratório.
- **Oracle (OCI):** Criação de um Compartimento (Compartment) exclusivo para o laboratório. Atribuição de políticas IAM permitindo gestão de recursos restritas a este compartimento, impedindo acesso ao root compartment ou a configurações de tenancy.

## Justificativa
1. **Segurança e Zero Trust:** Reduz drasticamente a superfície de ataque. Se o token OIDC vazar, o atacante só poderá interagir com os recursos isolados do laboratório, sem capacidade de escalar privilégios (Privilege Escalation).
2. **Prevenção de Erros Operacionais ("Fat Finger"):** Evita que um bug no código do IaC (ex: uma variável mal configurada) apague ou modifique recursos críticos fora do escopo do projeto.
3. **Compliance e Governança:** Atende requisitos de auditoria (SOC 2, ISO 27001, LGPD) que exigem segregação de duties (SoD) e aplicação rigorosa de menor privilégio em ambientes de CI/CD.
4. **Sustentabilidade Operacional:** Utilizar papéis predefinidos (Azure/GCP) ou Managed Policies (AWS) com guardrails é mais sustentável do que escrever políticas 100% customizadas do zero, que exigiriam manutenção constante a cada nova API lançada pelas clouds.

## Alternativas consideradas
**Alternativa 1: AdministratorAccess / Owner Global**<br>
Descrição: Atribuir permissões administrativas completas às Roles federadas para garantir que o deploy nunca falhe por falta de permissão.<br>

**Por que foi descartada?**<br>
Risco altíssimo de blast radius ilimitado. Violação direta das melhores práticas de segurança cloud e Zero Trust. Inaceitável em qualquer ambiente corporativo real.<br>

**Alternativa 2: Políticas 100% Customizadas do Zero para cada API**<br>
Descrição: Mapear cada ação de API necessária (ex: ec2:RunInstances, s3:PutObject) e criar policies customizadas granulares do zero.<br> 

**Por que foi descartada?** Custo de manutenção altíssimo. As clouds atualizam APIs constantemente. O esforço para manter essas policies em dia geraria "toil" excessivo para a equipe de SRE.<br>

**Alternativa 3: Workload Identity específica por Cloud**<br>
Descrição: Dar permissões amplas, mas usar condições de IAM para bloquear ações em recursos que não possuam a tag Project=Lab-MultiCloud.<br>

**Por que foi descartada?**<br>
Embora seja uma boa prática complementar, confiar apenas em tags é arriscado. Se um recurso for criado sem a tag (por erro humano ou bug no código), ele ficaria desprotegido. A restrição por escopo (Resource Group/Projeto/ARN) é mais robusta.

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Blast Radius Contido:** O impacto de qualquer falha de segurança ou erro operacional está estritamente limitado aos recursos do laboratório. | **Complexidade Inicial:** O mapeamento das permissões exatas necessárias exigirá tempo e iteração. |
| **Cultura de Segurança:** Estabelece um padrão de "Security by Design" para o projeto, servindo de exemplo para futuras iniciativas. | **Risco de "Access Denied" durante o Desenvolvimento:** É comum que o pipeline falhe no início por falta de alguma permissão específica (ex: uma API de tagging ou de métricas que foi esquecida). |
| **Auditoria Simplificada:** Fica muito mais fácil para auditores verificarem que o pipeline de IaC não possui privilégios excessivos. Logs claros e rastreáveis de qual identidade federada executou qual ação em qual cloud, facilitando troubleshooting e compliance. | **Sobrecarga Cognitiva:** A equipe precisa entender as nuances de IAM em três clouds diferentes simultaneamente. |

## Mitigações
- **Logs de Auditoria:** Uso intensivo do AWS CloudTrail, Azure Monitor, GCP Audit Logs e OCI Audit Logs para identificar permissões faltantes (erros 403) e ajustá-las de forma iterativa.
- **Ambiente de Sandbox:** Testar as políticas em um ambiente isolado antes de aplicá-las no pipeline principal.
- **Documentação:** Manter um inventário atualizado das Roles e suas permissões no repositório do projeto.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 07-08-2026 | Primeira versão  | Documentar a decisão de arquitetura de IAM e menor privilégio para os pipelines de IaC | Estabelece os guardrails de segurança para todo o provisionamento do projeto | Emershow |