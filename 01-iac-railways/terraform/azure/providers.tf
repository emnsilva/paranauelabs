# providers.tf
# Configura a conexão com o Azure.
#
# AUTENTICAÇÃO: Não há client_secret aqui.
# A autenticação é feita via OIDC, injetada automaticamente
# pelo Variable Set do TFC (TFC_AZURE_PROVIDER_AUTH = true).
# O TFC assume o App Registration configurado.

provider "azurerm" {
  features {}
  
  # default_tags aplica tags automaticamente em TODOS os recursos
  # criados por este provider. Essencial para FinOps e Auditoria.
  default_tags {
    tags = {
      Project     = "paranauelabs"
      Environment = var.ENVIRONMENT
      ManagedBy   = "terraform"
      owner       = "emershow"
      cost_center = "sre"
    }
  }
}