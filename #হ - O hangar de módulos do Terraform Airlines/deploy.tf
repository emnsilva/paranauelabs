# deploy.tf - Chamada dos módulos dos 3 provedores (AWS, Azure, GCP)
# Chama os módulos de cada provedor para criar os recursos de armazenamento

# Módulo AWS - Cria buckets S3 em duas regiões
module "aws_storage" {
  source = "./modules/aws"

  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }

  primary_region   = var.AWS_REGION_PRIMARY
  secondary_region = var.AWS_REGION_SECONDARY
}

# Módulo Azure - Cria storage accounts e containers em duas regiões
module "azure_storage" {
  source = "./modules/azure"

  providers = {
    azurerm.primary   = azurerm.primary
    azurerm.secondary = azurerm.secondary
  }

  primary_region   = var.ARM_PRIMARY_REGION
  secondary_region = var.ARM_SECONDARY_REGION
}

# Módulo GCP - Cria buckets de storage em duas regiões
module "gcp_storage" {
  source = "./modules/gcp"

  providers = {
    google.primary   = google.primary
    google.secondary = google.secondary
  }

  project_id       = var.GCP_PROJECT
  primary_region   = var.GCP_PRIMARY_REGION
  secondary_region = var.GCP_SECONDARY_REGION
}