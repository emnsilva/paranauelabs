# providers.tf
# Configura as conexões com a AWS em duas regiões, usando
# "alias" para distinguir cada uma.
#
# AUTENTICAÇÃO: Não há access_key/secret_key aqui.
# A autenticação é feita via OIDC, injetada automaticamente
# pelo Variable Set do TFC (TFC_AWS_PROVIDER_AUTH = true).
# O TFC gera um token temporário e assume a Role configurada.

# Provider PRIMÁRIO
provider "aws" {
  alias  = "primary"
  region = var.AWS_REGION_PRIMARY

  # default_tags aplica tags automaticamente em TODOS os recursos
  # criados por este provider. Essencial para FinOps e Auditoria.
  default_tags {
    tags = {
      Project     = "Paranauê Labs"
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Owner       = "Emershow"
      CostCenter  = "SRE"
      Region      = "primary"
    }
  }
}

# Provider SECUNDÁRIO
# Usado para Disaster Recovery (DR) e redundância multi-region.
provider "aws" {
  alias  = "secondary"
  region = var.AWS_REGION_SECONDARY

  default_tags {
    tags = {
      Project     = "Paranauê Labs"
      Environment = var.environment
      ManagedBy   = "OpenTofu"
      Owner       = "Emershow"
      CostCenter  = "SRE"
      Region      = "secondary"
    }
  }
}