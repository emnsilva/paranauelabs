# Este arquivo define como o Terraform se comunica com cada provedor

# 1. Especificação da  versão dos providers
# Define quais "rádios" serão usados e suas versões compatíveis
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.25.0"      # Versão mais recente até o momento
      configuration_aliases = [aws.primary, aws.secondary]
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.55.0"     # Versão mais recente até o momento
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.13.0"     # Versão mais recente até o momento
    }
  }
}

# 2. Provedor AWS - Canais primário e secundário
# Dois "canais" no mesmo rádio AWS para regiões diferentes

provider "aws" {
  alias  = "primary"                    # Canal primário
  region = var.AWS_REGION_PRIMARY       # Região definida nas variáveis
}

provider "aws" {
  alias  = "secondary"                  # Canal secundário
  region = var.AWS_REGION_SECONDARY     # Região definida nas variáveis
}

# 3. Provedor AZURE - Canais primário e secundário
# Dois "canais" no mesmo rádio Azure para regiões diferentes

provider "azurerm" {
  alias   = "primary"                   # Canal primário
  features {}                     c      # Configuração padrão do Azure
}

provider "azurerm" {
  alias   = "secondary"                 # Canal secundário
  features {}                           # Configuração padrão do Azure
}

# 4. Provedor GCP - Canais primário e secundário
# Dois "canais" no mesmo rádio GCP com configuração inteligente

provider "google" {
  alias   = "primary"                   # Canal primário
  project = var.GCP_PROJECT             # Projeto definido nas variáveis
  region  = var.GCP_PRIMARY_REGION      # Região primária definida nas variáveis
  
  # Credenciais inteligentes: usa OIDC quando disponível, estática quando necessário
  credentials = var.GOOGLE_CREDENTIALS_B64 != null ? base64decode(var.GOOGLE_CREDENTIALS_B64) : null
}

provider "google" {
  alias   = "secondary"                 # Canal secundário
  project = var.GCP_PROJECT             # Mesmo projeto
  region  = var.GCP_SECONDARY_REGION    # Região secundária definida nas variáveis
  
  # Mesma lógica de credenciais inteligentes
  credentials = var.GOOGLE_CREDENTIALS_B64 != null ? base64decode(var.GOOGLE_CREDENTIALS_B64) : null
}