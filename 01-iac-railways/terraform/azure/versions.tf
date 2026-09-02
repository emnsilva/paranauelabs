terraform {
  required_version = ">= 1.16.0"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 5.3.0"
    }
  }

  cloud {
    hostname     = "app.terraform.io"
    organization = "ParanaueLabs" # Substitua pelo nome exato da sua org no TFC

    workspaces {
      tags = ["azure"]
    }
  }
}