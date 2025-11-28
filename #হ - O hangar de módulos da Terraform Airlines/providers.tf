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

provider "aws" {
  alias  = "primary"
  region = var.AWS_REGION_PRIMARY
}

provider "aws" {
  alias  = "secondary"
  region = var.AWS_REGION_SECONDARY
}

provider "azurerm" {
  alias   = "primary"
  features {}
}

provider "azurerm" {
  alias   = "secondary"
  features {}
}

provider "google" {
  alias   = "primary"
  project = var.GCP_PROJECT
  region  = var.GCP_PRIMARY_REGION
  credentials = var.GOOGLE_CREDENTIALS_B64 != null ? base64decode(var.GOOGLE_CREDENTIALS_B64) : null
}

provider "google" {
  alias   = "secondary"
  project = var.GCP_PROJECT
  region  = var.GCP_SECONDARY_REGION
  credentials = var.GOOGLE_CREDENTIALS_B64 != null ? base64decode(var.GOOGLE_CREDENTIALS_B64) : null
}