# CONFIGURAÇÃO DE PROVEDORES REQUERIDOS
# Define quais "plugins" o Terraform precisa baixar e instalar
# Cada provedor é um componente que sabe conversar com uma nuvem específica
terraform {
  required_providers {
    # Provedor Azure - Microsoft Azure
    azurerm = {
      source  = "hashicorp/azurerm" # Fonte oficial da HashiCorp
      version = "~> 4.40.0"         # Versão aproximadamente 4.40.0
    }
  }
}
