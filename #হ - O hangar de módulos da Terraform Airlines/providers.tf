# CONFIGURAÇÃO DE PROVEDORES REQUERIDOS
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40.0"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.48.0"
    }
  }
}

# CONFIGURAÇÃO DOS PROVIDERS COM ALIASES
provider "aws" {
  alias  = "primary"
  region = var.AWS_REGION_PRIMARY
}

provider "aws" {
  alias  = "secondary"
  region = var.AWS_REGION_SECONDARY
}

provider "azurerm" {
  alias           = "primary"
  features {}
  
  subscription_id = var.ARM_SUBSCRIPTION_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  tenant_id       = var.ARM_TENANT_ID
}

provider "azurerm" {
  alias           = "secondary"
  features {}
  
  subscription_id = var.ARM_SUBSCRIPTION_ID
  client_id       = var.ARM_CLIENT_ID
  client_secret   = var.ARM_CLIENT_SECRET
  tenant_id       = var.ARM_TENANT_ID
}

provider "google" {
  alias   = "primary"
  project = var.GCP_PROJECT
  region  = var.GCP_PRIMARY_REGION
}

provider "google" {
  alias   = "secondary"
  project = var.GCP_PROJECT
  region  = var.GCP_SECONDARY_REGION
}
