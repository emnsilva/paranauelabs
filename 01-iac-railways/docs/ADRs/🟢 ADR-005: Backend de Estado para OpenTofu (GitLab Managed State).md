Número do ADR: 005<br>
Data: 29-08-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto IaC Multi-Cloud<br>
Status: 🟢 Aceito

## Contexto
Na Release 1, utilizamos o Terraform Cloud (TFC) como backend para o Terraform. Para a Release 2, introduziremos o OpenTofu. Em um ambiente anterior (GitLab), o OpenTofu utilizava o backend HTTP nativo do GitLab (GitLab Managed State). No entanto, no repositório do GitHub, o GitHub Actions não possui um backend HTTP nativo para gerenciar estados de IaC. O problema é: onde guardar o estado (tfstate) e gerenciar os bloqueios (state lock) do OpenTofu de forma segura, gratuita e centralizada neste novo repositório?

## Decisão
Adotar o Terraform Cloud (TFC) como solução de backend também para o OpenTofu neste repositório.<br>

A implementação seguirá as seguintes diretrizes:<br>

1. O bloco cloud {} será mantido no arquivo versions.tf do OpenTofu, apontando para a mesma organização do TFC usada pelo Terraform (ex: ParanaueLabs).
2. Serão criados Workspaces específicos para o OpenTofu no TFC (ex: dev_aws_tofu, staging_aws_tofu, prod_aws_tofu), mantendo o isolamento de estado em relação ao Terraform (que usa dev_aws_oidc, etc).
3. A autenticação do GitHub Actions com o TFC continuará sendo feita via API Token (TF_TOKEN_app_terraform_io) injetado como Secret.
4. A autenticação do TFC com a AWS continuará usando o OIDC nativo do TFC (TFC_AWS_RUN_ROLE_ARN), ajustando a Trust Policy da Role na AWS para aceitar o curinga dev_aws_* (permitindo tanto o workspace do Terraform quanto do OpenTofu).

## Justificativa
1. **Ausência de Backend Nativo no GitHub:** Diferente do GitLab, o GitHub não oferece um endpoint HTTP para guardar tfstate. Usar o TFC evita a necessidade de provisionar e configurar infraestrutura manual de S3 + DynamoDB na AWS apenas para guardar o estado.
2. **Custo e Toil Zero:** O TFC Managed State é gratuito e não exige a criação de buckets, tabelas (DynamoDB) ou permissões extras de infraestrutura em cada uma das 4 clouds futuras (Azure, GCP, OCI).
3. **Centralização:** Mantém o código, o pipeline (GitHub Actions) e o estado de ambas as ferramentas (Terraform e OpenTofu) gerenciados pelo mesmo backend visual (Terraform Cloud).
4. **Paridade de Arquitetura:** Garante que o OpenTofu tenha exatamente a mesma robustez de State Lock e Execução Remota que o Terraform possui neste repositório.

## Alternativas consideradas
**Alternativa 1: AWS S3 + DynamoDB**<br>
Descrição: Usar o serviço de armazenamento de objetos da AWS para o state e o DynamoDB para o lock.<br>

**Por que foi descartada?** <br>
Exige o trabalho de criar e configurar o S3 e o DynamoDB manualmente (bootstrap) antes de rodar o resto da infraestrutura. Quando o projeto expandir para Azure, GCP e Oracle na R3, exigirá a configuração de backends nativos em cada uma dessas clouds, aumentando o toil operacional.<br>

**Alternativa 2: Continuar usando o GitLab Managed State (HTTP)**<br>
Descrição: Migrar o repositório para o GitLab para usar o backend HTTP nativo deles.

**Por que foi descartada?**<br>
O objetivo deste repositório é demonstrar proficiência no GitHub Actions. Remover o repositório do GitHub anula o propósito do portfólio duplo (GitLab + GitHub).

**Alternativa 3: Spacelift ou env0**<br>
Descrição: Adotar uma plataforma SaaS moderna de automação de IaC.<br>

**Por que foi descartada?**<br>
Adiciona mais uma ferramenta externa a ser gerenciada, fugindo do escopo de validar o paralelismo entre Terraform e OpenTofu usando infraestrutura já estabelecida (TFC).

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Estado Centralizado:** O estado do OpenTofu e do Terraform ficam no mesmo painel (TFC), facilitando a auditoria e comparação. | **Dependência do TFC:** O OpenTofu fica dependente da disponibilidade e limites do plano Free do Terraform Cloud, assim como o Terraform. |
| **Setup Limpo:** Não requer infraestrutura de backend (S3/DynamoDB) para ser mantida. | **Isolamento de Workspaces:** Exige disciplina para criar e nomear workspaces distintos (_tofu vs _oidc) para que o estado das duas ferramentas não se sobrescreva. |
| **Segurança Mantida:** O OIDC do TFC para AWS funciona perfeitamente para o OpenTofu, exigindo apenas um ajuste de curinga na Trust Policy da AWS. | **Interface Limitada:** A visualização do estado no TFC é mais básica do que ferramentas focadas exclusivamente em gestão de estado. |

## Mitigações
- **Padronização de Nomenclatura:** Para mitigar o risco de sobreposição, os workspaces do OpenTofu terão o sufixo _tofu e os do Terraform _oidc, garantindo que nunca compartilhem o mesmo arquivo de estado.
- **Monitoramento de Limites:** Acompanhar o uso de execuções paralelas no TFC, pois agora o limite é compartilhado entre Terraform e OpenTofu.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 29-08-2026 | Primeira versão  | Documentar a decisão de usar o Terraform Cloud como backend para o OpenTofu no GitHub, já que o GitHub não possui backend HTTP nativo. | Estabelece a arquitetura de estado para a Release 2. | Emershow |