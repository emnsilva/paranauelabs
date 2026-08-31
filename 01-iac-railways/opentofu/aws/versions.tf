terraform {
  required_version = ">= 1.12.6"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62.0"
    }
  }

  cloud {
    hostname     = "app.terraform.io"
    organization = "ParanaueLabs"
  
    workspaces {
      tags = ["aws"]
    }
  }
}