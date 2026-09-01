Número do ADR: 004<br>
Data: 14-08-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto IaC Multi-Cloud<br>
Status: 🟢 Aceito

## Contexto
O projeto IaC Railways utiliza o Terraform e o OpenTofu para provisionar infraestrutura em 4 clouds diferentes. Para garantir a integridade do estado (state file) e evitar condições de corrida durante execuções paralelas, é obrigatório o uso de um backend remoto com bloqueio (state lock).

O Terraform Cloud (TFC) foi escolhido como solução de backend. O problema central é: como configurar o TFC para que ele forneça o state lock e a execução remota, sem que ele assuma o controle do código-fonte ou passe por cima da esteira de CI/CD e governança (GMUDs) que foi desenhada no GitHub Actions? Adicionalmente, como organizar os workspaces e variáveis para suportar a matriz 2x4 (Ferramentas x Clouds) em múltiplos ambientes sem gerar duplicação de configuração?

## Decisão
Adotar o modo CLI-driven puro (No VCS connection) no Terraform Cloud, estruturar os workspaces por Ambiente e Cloud/Ferramenta, e gerenciar as variáveis exclusivamente através de Variable Sets.<br>

A implementação seguirá as seguintes diretrizes:<br>
1. **Modo de Execução (CLI-driven puro):** O GitHub Actions será o orquestrador universal. O repositório do GitHub permanecerá a única fonte da verdade. O pipeline do GitHub Actions usará um API Token (armazenado como secret mascarada) para enviar o código ao TFC apenas no momento do terraform/tofu plan ou apply. O TFC atuará estritamente como backend remoto e gerenciador de state lock.
2. **Estrutura de Workspaces:** Criação de um Project no TFC chamado iac-railways-oidc. Dentro dele, os workspaces seguirão o padrão de nomenclatura <ambiente>_<cloud>_<ferramenta> (ex: dev_aws_oidc para Terraform, dev_aws_tofu para OpenTofu). Workspaces de Terraform e OpenTofu serão separados para evitar conflitos de lock do mesmo state.
3. **Gestão de Variáveis (Variable Sets):** Descontinuação do uso de variáveis locais no TFC em favor de Variable Sets:
 - Variable Set Global: Aplicado a todos os workspaces (ex: TF_LOG=INFO, tags padrão de FinOps).
 - Variable Sets por Cloud/Ambiente: Configurando o OIDC nativo do TFC (ex: TFC_AWS_RUN_ROLE_ARN para a Role de Dev), permitindo que o próprio TFC assuma a role na nuvem durante a execução, mantendo a autenticação 100% passwordless.

## Justificativa
1. **Governança Centralizada no GitHub:** O modo VCS-driven (onde o TFC puxa o código) foi descartado pois ele ignora a esteira do GitHub Actions, bypassando Linting customizado e regras de aprovação de GMUD. Usando o CLI-driven puro, garantimos que todo fluxo passe pelo pipeline do GitHub antes de falar com o TFC.
2. **Segurança e Isolamento de Segredos:** O GitHub Actions não precisa armazenar credenciais das clouds. O TFC assume a role na nuvem via OIDC nativo configurado nos Variable Sets, centralizando a gestão de segredos e reduzindo a superfície de ataque no pipeline.
3. **Prevenção de Conflitos:** Separar os workspaces por ferramenta (ex: dev_aws_oidc e dev_aws_tofu) garante que, se ambas as esteiras rodarem em paralelo, não haverá bloqueio cruzado do mesmo state file.
4. **Manutenibilidade (DRY):** O uso de Variable Sets evita a repetição de configuração de OIDC e tags em dezenas de workspaces, aplicando o princípio DRY (Don't Repeat Yourself) na gestão de variáveis.

## Alternativas consideradas
**Alternativa 1: Modo VCS-driven**<br>
Descrição: Conectar o TFC ao repositório do GitHub via OAuth. O TFC detectaria os commits e rodaria o plan/apply automaticamente.<br>

**Por que foi descartada?** <br>
 Ignora a esteira de CI/CD do GitHub Actions, bypassando regras de aprovação de GMUD e duplicando a fonte de verdade do fluxo de trabalho.<br>

**Alternativa 2: Backend Local no Runner do GitHub Actions**<br>
Descrição: Guardar o tfstate como artefato no próprio GitHub Actions, sem usar o TFC.<br>

**Por que foi descartada?**<br>
Falta de state lock nativo e robusto, gerando risco altíssimo de corrupção de estado em execuções paralelas.<br>

**Alternativa 3: Backends Nativos de cada Cloud (S3, Azure Blob, GCS)**<br>
Descrição: Usar o serviço de armazenamento de objetos de cada cloud para guardar o state (ex: S3 + DynamoDB na AWS).<br>

**Por que foi descartada?**<br>
Exige criação e manutenção de infraestrutura de backend em 4 clouds diferentes. O TFC oferece uma interface unificada, gratuita para laboratórios, com lock nativo e execução remota centralizada.

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Governança Única:** O GitHub Actions mantém 100% do controle do fluxo de CI/CD, com o TFC atuando apenas como "cofre" do estado. | **Dependência de Conectividade:** O pipeline do GitHub depende que a API do TFC esteja online e acessível. Falhas na API do TFC paralisam os deploys. |
| **State Lock Robusto:** Eliminação total do risco de concorrência, garantindo integridade do tfstate. | **Limites da Versão Free:** O TFC gratuito possui limites de execuções simultâneas e usuários, o que pode exigir gestão de filas em momentos de pico da matriz. |
| **Segurança Centralizada:** As Roles de OIDC das clouds ficam configuradas apenas no TFC, reduzindo exposição no repositório de código. | **Overhead de Execução:** O modo CLI-driven adiciona um pequeno overhead de rede ao enviar o código do GitHub para o TFC antes de rodar o plan/apply. |
| **Paridade OpenTofu:** A estrutura suporta o OpenTofu sem mudanças arquiteturais, apenas criando novos workspaces. | **Gestão de Tokens:** É necessário rotacionar e gerenciar o API Token do TFC nas variáveis do GitLab de forma segura. |

## Mitigações
- **Variáveis Protegidas:** O API Token do TFC será configurado no GitHub Actions como variável Masked e restrita ao Environment correto.
- **Monitoramento de Limites:** Acompanhar o uso de minutos paralelos no painel do TFC para evitar bloqueios inesperados durante a execução da matriz.
- **Documentação de Variáveis:** Manter um inventário atualizado no repositório detalhando quais Variable Sets existem no TFC e quais variáveis eles injetam.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 14-08-2026 | Primeira versão  | Documentar a arquitetura de execução CLI-driven, workspaces e variable sets no TFC | Documentar a arquitetura de execução CLI-driven, workspaces e variable sets no TFC | Emershow |