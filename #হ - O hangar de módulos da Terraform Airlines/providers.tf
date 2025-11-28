# CONFIGURAÇÃO DE PROVEDORES REQUERIDOS
# Define quais "plugins" o Terraform precisa baixar e instalar
# Cada provedor é um componente que sabe conversar com uma nuvem específica
terraform {
  required_providers {
    # Provedor AWS - Amazon Web Services
    aws = {
      source  = "hashicorp/aws"    # Fonte oficial da HashiCorp
      version = "~> 6.9.0"         # Versão aproximadamente 6.9.0
    }
    
    # Provedor Azure - Microsoft Azure
    azurerm = {
      source  = "hashicorp/azurerm" # Fonte oficial da HashiCorp
      version = "~> 4.40.0"         # Versão aproximadamente 4.40.0
    }
    
    # Provedor Google - Google Cloud Platform
    google = {
      source  = "hashicorp/google"  # Fonte oficial da HashiCorp
      version = "~> 6.48.0"         # Versão aproximadamente 6.48.0
    }
  }
}

# AWS Providers
provider "aws" {
  alias  = "primary"
  region = var.AWS_REGION_PRIMARY
}

provider "aws" {
  alias  = "secondary"  
  region = var.AWS_REGION_SECONDARY
}

# Azure Providers  
provider "azurerm" {
  alias           = "primary"
  subscription_id = var.ARM_SUBSCRIPTION_ID
  features {}
}

provider "azurerm" {
  alias           = "secondary"
  subscription_id = var.ARM_SUBSCRIPTION_ID
  features {}
}

# GCP Providers
provider "google" {
  alias = "primary"
}

provider "google" {
  alias = "secondary"
}
