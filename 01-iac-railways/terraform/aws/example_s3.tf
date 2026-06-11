# Define quais "plugins" o Terraform precisa baixar e instalar
terraform {
  required_providers {
    # Provedor AWS - Amazon Web Services
    aws = {
      source  = "hashicorp/aws"    # Fonte oficial da HashiCorp
      version = "~> 6.48.0"        # Versão aproximadamente 6.48.0
    }
    # Provedor Random - Para gerar nomes únicos globais
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.0"
    }
  }
}

# Cria um sufixo único para evitar conflitos de nomes globais da AWS
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Variáveis de configuração AWS
# Define as regiões AWS onde os buckets serão criados
variable "AWS_REGION_PRIMARY" {}
variable "AWS_REGION_SECONDARY" {}

# Provedores AWS
# Configura conexões com a AWS em duas regiões diferentes
provider "aws" {
  alias  = "primary"
  region = var.AWS_REGION_PRIMARY
}

provider "aws" {
  alias  = "secondary"
  region = var.AWS_REGION_SECONDARY
}

# Buckets S3 AWS
# Cria "pastas gigantes" na nuvem da AWS para armazenamento de objetos
# O nome precisa ser único globalmente, por isso usamos o sufixo aleatório
resource "aws_s3_bucket" "primary" {
  provider      = aws.primary
  bucket        = "primary-bucket-${random_string.suffix.result}" # Nome único global
  force_destroy = true                  # Permite deletar mesmo com arquivos dentro (ideal para labs)
}

resource "aws_s3_bucket" "secondary" {
  provider      = aws.secondary
  bucket        = "secondary-bucket-${random_string.suffix.result}" # Nome único global
  force_destroy = true                  # Permite deletar mesmo com arquivos dentro (ideal para labs)
}