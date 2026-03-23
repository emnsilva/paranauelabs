# Configuração geral do Terraform
# Define os provedores e as versões aceitas.
# '~>' permite atualizações de patch, mas bloqueia mudanças drásticas (ex: para 6.0 para 7.0).

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
      # Essencial: Declara que vamos passar esses aliases para os módulos
      configuration_aliases = [aws.primary, aws.secondary]
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.0"
      configuration_aliases = [azurerm.primary, azurerm.secondary]
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
      configuration_aliases = [google.primary, google.secondary]
    }
  }
}

# As credenciais são injetadas automaticamente pelo Terraform Cloud.
# Não precisamos declarar access_key ou secret_key aqui.
# Nota: O provider Azure não tem argumento 'region', a localização é definida em cada recurso.

provider "aws" {
  alias  = "primary"
  region = var.AWS_REGION_PRIMARY # Vem do variables.tf (que vem do TFC)
}

provider "aws" {
  alias  = "secondary"
  region = var.AWS_REGION_SECONDARY
}

provider "azurerm" {
  alias = "primary"
  features {} # Necessário para o provider Azure funcionar
}

provider "azurerm" {
  alias = "secondary"
  features {}
}

provider "google" {
  alias   = "primary"
  project = var.GCP_PROJECT
  region  = var.GCP_PRIMARY_REGION

  # Lógica Híbrida:
  # Se a variável GOOGLE_CREDENTIALS_B64 tiver valor, decodifica e usa.
  # Se for null, tenta usar o OIDC (Workload Identity) configurado no TFC.
  credentials = var.GOOGLE_CREDENTIALS_B64 != null ? base64decode(var.GOOGLE_CREDENTIALS_B64) : null
}

provider "google" {
  alias   = "secondary"
  project = var.GCP_PROJECT
  region  = var.GCP_SECONDARY_REGION
  credentials = var.GOOGLE_CREDENTIALS_B64 != null ? base64decode(var.GOOGLE_CREDENTIALS_B64) : null
}