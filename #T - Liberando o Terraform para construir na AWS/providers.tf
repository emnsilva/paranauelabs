terraform {
  required_providers {
    aws = { source = "hashicorp/aws", version = "~> 6.9.0" }
    azurerm = { source = "hashicorp/azurerm", version = "~> 4.40.0" }
    google = { source = "hashicorp/google", version = "~> 6.48.0" }
  }
}
