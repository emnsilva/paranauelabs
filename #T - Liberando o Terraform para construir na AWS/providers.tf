terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.9.0" }
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.40.0" }
    google = { source = "hashicorp/google", version = "~> 6.48.0" }
  }
}

# Configuração dos providers
provider "aws" {
  region = local.regions.aws[var.CLOUD_PRIMARY_REGION]
  
  # Provider secundário (para failover/redundância)
  alias = "secondary"
  region = local.regions.aws[var.CLOUD_SECONDARY_REGION]
}

provider "azurerm" {
  features {}
  location = local.regions.azure[var.CLOUD_PRIMARY_REGION]
  
  # Provider secundário
  alias = "secondary"
  location = local.regions.azure[var.CLOUD_SECONDARY_REGION]
}

provider "google" {
  project = var.GCP_PROJECT_ID
  region = local.regions.gcp[var.CLOUD_PRIMARY_REGION]
  
  # Provider secundário
  alias = "secondary"
  region = local.regions.gcp[var.CLOUD_SECONDARY_REGION]
}
