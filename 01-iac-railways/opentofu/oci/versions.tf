terraform {
  required_version = ">= 1.12.6"

  required_providers {
    oci = {
      source  = "oracle/oci"
      version = "~> 9.0.0"
    }
  }

  cloud {
    hostname     = "app.terraform.io"
    organization = "ParanaueLabs"

    workspaces {
      tags = ["oci"]
    }
  }
}