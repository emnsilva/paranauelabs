# providers.tf
# Configura a conexão com o GCP.
#
# AUTENTICAÇÃO: Não há chaves JSON estáticas aqui.
# A autenticação é feita via OIDC, injetada automaticamente
# pelo Variable Set do TFC (TFC_GOOGLE_PROVIDER_AUTH = true).
# O TFC assume a Workload Identity configurada.

provider "google" {
  project = var.GCP_PROJECT_ID
  region  = var.GCP_PRIMARY_REGION

  # default_labels aplica tags automaticamente em TODOS os recursos
  # criados por este provider. Essencial para FinOps e Auditoria.
  default_labels = {
    Project     = "paranauelabs"
    Environment = var.environment
    ManagedBy   = "Terraform"
    Owner       = "Emershow"
    CostCenter  = "SRE"
  }
}