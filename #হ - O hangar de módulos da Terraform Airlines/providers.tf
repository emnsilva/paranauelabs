# Define quais "plugins" o Terraform precisa baixar e instalar

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

# Providers AWS
provider "aws" {
  alias  = "primary"
  region = var.AWS_REGION_PRIMARY
}

provider "aws" {
  alias  = "secondary"
  region = var.AWS_REGION_SECONDARY
}

# Providers Azure
provider "azurerm" {
  alias   = "primary"
  features {}
}

provider "azurerm" {
  alias   = "secondary"
  features {}
}

# Providers GCP
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