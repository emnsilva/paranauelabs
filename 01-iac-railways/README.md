# IaC Railways

Laboratório multi-cloud de Infraestrutura como Código

Esse lab é um ambiente de estudo e experimentação para provisionar recursos em nuvem usando três ferramentas de IaC — Terraform, OpenTofu e Pulumi — em três provedores: AWS, Azure e GCP. O projeto compara abordagens, padrões de autenticação e fluxos de deploy, do laboratório local até pipelines CI/CD com OIDC.

## O que é o IaC Railways?

O **IaC Railways** foi criado para quem quer entender na prática como a mesma infraestrutura pode ser descrita e gerenciada com ferramentas diferentes. Em vez de focar em um único stack de produção, o repositório trata a infraestrutura como um sistema de aprendizado: cada diretório isola um provedor, uma ferramenta e um cenário de autenticação.

A filosofia do projeto é simples: **credenciais nunca entram no repositório**. Variáveis sensíveis ficam em arquivos `.env` locais (não versionados), em Pulumi Environments (ESC) ou são injetadas em tempo de execução via OIDC no GitHub Actions. Os exemplos usam `force_destroy` e recursos mínimos, pensados para labs — fáceis de subir e destruir sem custo significativo.

Seja para comparar Terraform com OpenTofu, testar Pulumi em YAML ou configurar autenticação federada na CI, este repositório oferece uma base consistente e documentada para experimentação multi-cloud.

## Funcionalidades

- **Três ferramentas de IaC**: Terraform, OpenTofu e Pulumi (runtime YAML) lado a lado, com exemplos equivalentes por provedor.
- **Multi-cloud**: Exemplos para AWS, Azure e GCP com padrões de região primária e secundária.
- **Armazenamento de objetos (Terraform / OpenTofu)**: Buckets S3, contas de Blob Storage e buckets GCS com sufixos aleatórios para evitar conflitos de nomes globais.
- **Máquinas virtuais (Pulumi)**: EC2, Azure VM e GCP Compute Instance com servidor HTTP simples embutido via `userData` / `customData` / `metadataStartupScript`.
- **Autenticação flexível**: Credenciais estáticas para desenvolvimento local; OIDC federado para pipelines GitHub Actions.
- **Pulumi Environments**: Templates de ambiente (`pulumi/environments/`) para centralizar credenciais e configuração por stack.
- **CI/CD pronta**: Workflows GitHub Actions executam `tofu plan` com autenticação OIDC em AWS, Azure e GCP.
- **Segurança por padrão**: `.gitignore` bloqueia stacks Pulumi locais e arquivos JSON de chaves; exemplos de `.env` sem valores reais.

## Visão geral da arquitetura

O repositório segue uma estrutura em camadas por ferramenta e provedor:

```
terraform/     → Exemplos declarativos (.tf) para armazenamento
opentofu/      → Mesmos exemplos, compatíveis com OpenTofu + CI OIDC
pulumi/        → Programas YAML para VMs + templates de environment
```

### Diagrama de fluxo

```
[Desenvolvedor] ──> [.env local / Pulumi ESC]
        │
        ├──> terraform init / plan / apply
        ├──> tofu init / plan / apply
        └──> pulumi up

[GitHub Actions] ──> [OIDC Token]
        │
        ├──> AWS IAM Role
        ├──> Azure AD App Registration
        └──> GCP Workload Identity Federation
                │
                └──> tofu plan (OpenTofu)
```

### Estrutura de diretórios

```
01-iac-railways/
├── terraform/teste/
│   ├── aws/example_s3.tf
│   ├── azure/example_blob.tf
│   └── gcp/example_storage.tf
├── opentofu/teste/
│   ├── aws/          # tofu_s3.tf + .env.example
│   ├── azure/        # tofu_blob.tf + .env.example
│   └── gcp/          # tofu_storage.tf + .env.example
├── pulumi/
│   ├── teste/
│   │   ├── aws/Pulumi.yaml    # EC2 + VPC
│   │   ├── azure/Pulumi.yaml  # VM Debian
│   │   └── gcp/Pulumi.yaml    # Compute Instance
│   └── environments/
│       ├── aws_environment
│       ├── azure_environment
│       └── gcp_environment
└── .gitignore
```

## Início rápido

### Pré-requisitos

| Ferramenta | Versão mínima | Uso |
|---|---|---|
| [Terraform](https://developer.hashicorp.com/terraform/downloads) | 1.5+ | Exemplos em `terraform/` |
| [OpenTofu](https://opentofu.org/docs/intro/install/) | 1.6+ | Exemplos em `opentofu/` |
| [Pulumi CLI](https://www.pulumi.com/docs/install/) | 3.x | Exemplos em `pulumi/` |
| Conta cloud | — | AWS, Azure e/ou GCP com permissões de criação de recursos |

### Terraform — armazenamento local

```bash
cd terraform/teste/aws   # ou azure/ ou gcp/

# Configure credenciais do provedor (veja seção Provedores)
export AWS_ACCESS_KEY_ID="..."
export AWS_SECRET_ACCESS_KEY="..."
export TF_VAR_AWS_REGION_PRIMARY="sa-east-1"
export TF_VAR_AWS_REGION_SECONDARY="us-east-1"

terraform init
terraform plan
terraform apply
```

### OpenTofu — armazenamento local

```bash
cd opentofu/teste/aws   # ou azure/ ou gcp/

cp .env.example .env
# Edite .env com suas credenciais e regiões
source .env

tofu init
tofu plan
tofu apply
```

### Pulumi — máquina virtual

```bash
cd pulumi/teste/aws   # ou azure/ ou gcp/

# Autentique no provedor (variáveis de ambiente ou ESC)
pulumi stack init dev
pulumi up
```

Após o deploy, o Pulumi exporta IP, hostname e URL do servidor HTTP:

```
Outputs:
  ip      : "203.0.113.42"
  hostname: "ec2-xx-xx-xx-xx.compute.amazonaws.com"
  url     : "http://ec2-xx-xx-xx-xx.compute.amazonaws.com"
```

## Configuração

Toda configuração é feita via variáveis de ambiente ou arquivos de stack Pulumi. **Nunca commite credenciais reais.**

### AWS

| Variável | Descrição | Obrigatória |
|---|---|---|
| `AWS_ACCESS_KEY_ID` | Chave de acesso IAM | Sim (local) |
| `AWS_SECRET_ACCESS_KEY` | Chave secreta IAM | Sim (local) |
| `TF_VAR_AWS_REGION_PRIMARY` | Região do bucket primário | Sim |
| `TF_VAR_AWS_REGION_SECONDARY` | Região do bucket secundário | Sim |

**Recursos criados**: dois buckets S3 (`primary-bucket-*` e `secondary-bucket-*`) em regiões distintas, com `force_destroy = true`.

### Azure

| Variável | Descrição | Obrigatória |
|---|---|---|
| `ARM_CLIENT_ID` | ID do App Registration | Sim |
| `ARM_CLIENT_SECRET` | Segredo do aplicativo | Sim |
| `ARM_SUBSCRIPTION_ID` | ID da assinatura | Sim |
| `ARM_TENANT_ID` | ID do tenant | Sim |
| `TF_VAR_ARM_PRIMARY_REGION` | Região primária (ex: `brazilsouth`) | Sim |
| `TF_VAR_ARM_SECONDARY_REGION` | Região secundária (ex: `eastus`) | Sim |

**Recursos criados**: dois resource groups, duas storage accounts e dois containers Blob privados.

### GCP

| Variável | Descrição | Obrigatória |
|---|---|---|
| `TF_VAR_GOOGLE_CREDENTIALS_B64` | Service Account JSON em Base64 | Sim (local) |
| `TF_VAR_GCP_PROJECT` | ID do projeto GCP | Sim |
| `TF_VAR_GCP_PRIMARY_REGION` | Região primária (ex: `southamerica-east1`) | Sim |
| `TF_VAR_GCP_SECONDARY_REGION` | Região secundária (ex: `us-east1`) | Sim |

**Recursos criados**: dois buckets GCS (`primary-storage-*` e `secondary-storage-*`) em regiões distintas.

> No CI com OIDC, o GCP não precisa de `GOOGLE_CREDENTIALS_B64` — o workflow injeta credenciais automaticamente via Workload Identity Federation.

## Provedores

### AWS

Os exemplos Terraform/OpenTofu provisionam armazenamento S3 multi-região. O exemplo Pulumi (`pulumi/teste/aws/`) sobe uma VPC completa com EC2 `t3.micro`, security group liberando porta 80 e um servidor HTTP via `userData`.

**Autenticação local**: chaves IAM estáticas via variáveis de ambiente.

**Autenticação CI**: OIDC com `aws-actions/configure-aws-credentials` assumindo uma IAM Role (`AWS_RUN_ROLE_ARN`).

### Azure

Os exemplos Terraform/OpenTofu criam contas de armazenamento Blob com replicação LRS. O Pulumi (`pulumi/teste/azure/`) provisiona uma VM Debian com IP público, NSG (portas 80 e 22) e chave SSH gerada automaticamente.

**Autenticação local**: Service Principal via `ARM_*`.

**Autenticação CI**: OIDC com `azure/login@v2` usando `ARM_CLIENT_ID`, `ARM_TENANT_ID` e `ARM_SUBSCRIPTION_ID` como GitHub Variables.

### GCP

Os exemplos Terraform/OpenTofu criam buckets GCS com `storage_class = STANDARD`. O Pulumi (`pulumi/teste/gcp/`) sobe uma instância `f1-micro` com firewall, subnet e servidor HTTP na inicialização.

**Autenticação local**: Service Account JSON codificado em Base64 (`TF_VAR_GOOGLE_CREDENTIALS_B64`) ou `GOOGLE_CREDENTIALS` no ESC.

**Autenticação CI**: Workload Identity Federation via `google-github-actions/auth@v2`.

## Pulumi Environments

Os arquivos em `pulumi/environments/` são templates para o [Pulumi ESC](https://www.pulumi.com/docs/esc/) — um lugar centralizado para credenciais e configuração de stack, sem expor segredos no repositório.

```bash
# Exemplo: importar environment AWS
pulumi env open <org>/aws_environment
```

Cada template define:

- **Regiões** primária e secundária por provedor
- **Credenciais** injetadas como `environmentVariables`
- **`pulumiConfig`** com prefixo do nome do projeto (ex: `gcp_vm_yaml:GCP_PROJECT`)

> Ao criar seu próprio environment, substitua os placeholders pelos valores reais e use o nome exato do seu projeto Pulumi como prefixo nas chaves de configuração.

## CI/CD com GitHub Actions

O repositório inclui três workflows em `.github/workflows/` que executam `tofu plan` a cada push na branch `main`:

| Workflow | Provedor | Autenticação |
|---|---|---|
| `opentofu_aws_oidc.yaml` | AWS | IAM Role via OIDC |
| `opentofu_azure_oidc.yaml` | Azure | Azure AD OIDC |
| `opentofu_gcp_oidc.yaml` | GCP | Workload Identity Federation |

### Variáveis necessárias no GitHub

Configure em **Settings → Secrets and variables → Actions → Variables**:

**AWS**
- `AWS_RUN_ROLE_ARN`
- `AWS_REGION_PRIMARY`
- `AWS_REGION_SECONDARY`

**Azure**
- `ARM_CLIENT_ID`
- `ARM_TENANT_ID`
- `ARM_SUBSCRIPTION_ID`
- `ARM_PRIMARY_REGION`
- `ARM_SECONDARY_REGION`

**GCP**
- `GCP_WORKLOAD_IDENTITY_PROVIDER`
- `GCP_SERVICE_ACCOUNT`
- `GCP_PROJECT`
- `GCP_PRIMARY_REGION`
- `GCP_SECONDARY_REGION`

O passo `tofu apply` está comentado nos workflows por segurança. Descomente-o quando estiver pronto para aplicar mudanças automaticamente na `main`.

## Segurança

- **Sem credenciais no repositório**: `.gitignore` exclui `Pulumi.*.yaml` (stacks locais) e `*.json` (chaves de service account).
- **OIDC em produção**: Pipelines CI usam tokens de curta duração em vez de chaves estáticas.
- **Labs destrutíveis**: Recursos de armazenamento usam `force_destroy = true` para facilitar teardown.
- **Princípio do menor privilégio**: Use roles/SPAs com permissões mínimas necessárias para cada provedor.
- **Não exponha outputs sensíveis**: O exemplo Azure exporta a chave SSH privada — adequado para lab, nunca para produção.

## Comparando as ferramentas

| Aspecto | Terraform | OpenTofu | Pulumi |
|---|---|---|---|
| Linguagem | HCL (.tf) | HCL (.tf) — compatível | YAML (neste repo) |
| Foco do exemplo | Armazenamento | Armazenamento + CI | Máquinas virtuais |
| Estado | Local ou remoto | Local ou remoto | Gerenciado pelo Pulumi Service |
| CI integrada | — | GitHub Actions OIDC | ESC Environments |
| Curva de aprendizado | Baixa | Baixa (drop-in) | Média |

## Perguntas frequentes

**P: Posso usar só um provedor?**
Sim. Cada diretório é independente. Escolha `aws/`, `azure/` ou `gcp/` conforme sua conta.

**P: Terraform e OpenTofu usam os mesmos arquivos?**
Quase. Os exemplos em `opentofu/` são equivalentes aos de `terraform/`, com a mesma sintaxe HCL. OpenTofu é um fork open-source compatível com o ecossistema Terraform.

**P: Por que dois buckets/contas em regiões diferentes?**
Para demonstrar providers com alias multi-região — um padrão comum em arquiteturas de resiliência e replicação geográfica.

**P: Como destruo tudo depois do lab?**

```bash
terraform destroy   # ou: tofu destroy
pulumi destroy
```

**P: O `tofu apply` na CI está desabilitado. Como habilitar?**
Descomente o bloco `OpenTofu Apply` / `Tofu Apply` no workflow correspondente em `.github/workflows/`. Certifique-se de que as variáveis GitHub estão configuradas e que a role/SP tem permissão de escrita.

**P: Preciso do Pulumi Service?**
Para stacks locais, sim — o CLI precisa de uma conta (gratuita para uso individual). Alternativamente, configure um backend self-hosted (S3, Azure Blob, etc.).

## Contribuindo

Contribuições são bem-vindas!

1. Mantenha exemplos mínimos e focados em aprendizado.
2. Nunca inclua credenciais, chaves ou IDs reais de projeto.
3. Documente novas variáveis nos `.env.example` correspondentes.
4. Teste localmente com `plan` antes de abrir um PR.

## Filosofia: laboratório vs. produção

Este repositório não pretende ser um template de produção. Ele existe para que você **experimente, compare e entenda** como diferentes ferramentas e provedores se comportam com os mesmos conceitos — regiões, providers com alias, autenticação federada e pipelines de IaC.

A diferença entre um lab e um ambiente real está nos detalhes: backends de estado remotos, políticas de `apply` protegidas, módulos reutilizáveis, testes com `terratest` ou `policy-as-code`, e segredos gerenciados por vaults dedicados. Use este projeto como ponto de partida e evolua a partir daí.

## Agradecimentos

Este laboratório é possível graças a projetos open-source fundamentais:

- [Terraform](https://www.terraform.io/) e [OpenTofu](https://opentofu.org/) pela base declarativa de IaC
- [Pulumi](https://www.pulumi.com/) pela abordagem imperativa com linguagens familiares
- [HashiCorp Providers](https://registry.terraform.io/) (AWS, AzureRM, Google) pelos plugins oficiais
- [GitHub Actions](https://github.com/features/actions) pelos workflows de CI com OIDC

---

**Aproveitem!**
