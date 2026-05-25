# CONFIGURAÇÃO DE PROVEDORES REQUERIDOS
# Define quais "plugins" o Terraform precisa baixar e instalar
# Cada provedor é um componente que sabe conversar com uma nuvem específica
terraform {
  required_providers {
    # Provedor AWS - Amazon Web Services
    aws = {
      source  = "hashicorp/aws"    # Fonte oficial da HashiCorp
      version = "~> 6.9.0"         # Versão aproximadamente 6.9.0
    }
  }
}
