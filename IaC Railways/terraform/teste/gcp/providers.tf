# CONFIGURAÇÃO DE PROVEDORES REQUERIDOS
# Define quais "plugins" o Terraform precisa baixar e instalar
# Cada provedor é um componente que sabe conversar com uma nuvem específica
terraform {
  required_providers {
    # Provedor Google - Google Cloud Platform
    google = {
      source  = "hashicorp/google"  # Fonte oficial da HashiCorp
      version = "~> 6.48.0"         # Versão aproximadamente 6.48.0
    }
  }
}
