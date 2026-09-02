
terraform {
  required_version = ">= 1.12.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.1.0"
    }
  }

  cloud {
    hostname     = "app.terraform.io"
    organization = "ParanaueLabs" # Substitua pelo nome exato da sua org no TFC

    workspaces {
      tags = ["gcp"]
    }
  }
}