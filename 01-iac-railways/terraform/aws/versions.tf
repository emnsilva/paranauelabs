terraform {
  required_version = ">= 1.16.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.62.0"
    }
  }

  cloud {
    organization = "ParanaueLabs"
  
    workspaces {
      tags = ["aws"]
    }
  }
}