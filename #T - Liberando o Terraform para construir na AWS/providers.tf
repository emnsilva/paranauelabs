terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
    # Adicione o Google Provider aqui ↓
    google = {
      source  = "hashicorp/google"
      version = "~> 6.48.0"  # Versão recomendada (consulte a mais recente)
    }
  }
}
