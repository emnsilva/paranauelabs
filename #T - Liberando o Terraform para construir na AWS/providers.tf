terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.9.0" }
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.40.0" }
    google = { source = "hashicorp/google", version = "~> 6.48.0" }
  }
}

# Configuração PRIMÁRIA (sem alias)
provider "aws" {
  alias = "primary"
  region = local.regions.aws[var.CLOUD_PRIMARY_REGION]
}

provider "azurerm" {
  alias = "primary"
  features {}
  location = local.regions.azure[var.CLOUD_PRIMARY_REGION]
}

provider "google" {
  alias = "primary"
  project = var.GCP_PROJECT_ID
  region  = local.regions.gcp[var.CLOUD_PRIMARY_REGION]
}

# Configuração SECUNDÁRIA (com alias explícito)
provider "aws" {
  alias  = "secondary"
  region = local.regions.aws[var.CLOUD_SECONDARY_REGION]
}

provider "azurerm" {
  alias    = "secondary"
  features {}
  location = local.regions.azure[var.CLOUD_SECONDARY_REGION]
}

provider "google" {
  alias   = "secondary"
  project = var.GCP_PROJECT_ID
  region  = local.regions.gcp[var.CLOUD_SECONDARY_REGION]
}
