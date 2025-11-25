# deployment.tf - Orquestrando todos os módulos da Terraform Airlines

# AWS storage modules
module "aws_primary_storage" {
  source         = "./modules/s3-storage"
  bucket_name    = "primary-bucket-modular"
  provider_alias = "primary"
  region         = var.AWS_REGION_PRIMARY
  force_destroy  = false
  tags = {
    Ambiente   = "production"
    Projeto    = "terraform-airlines"
    Componente = "storage"
  }
}

module "aws_secondary_storage" {
  source         = "./modules/s3-storage"
  bucket_name    = "secondary-bucket-modular" 
  provider_alias = "secondary"
  region         = var.AWS_REGION_SECONDARY
  force_destroy  = true
  tags = {
    Ambiente   = "backup"
    Projeto    = "terraform-airlines"
    Componente = "storage"
  }
}

# Azure storage modules
module "azure_primary_storage" {
  source                = "./modules/blob-storage"
  storage_account_name  = "primarystorage${random_id.suffix.hex}"
  resource_group_name   = "primary-blob-storage-${random_id.suffix.hex}"
  location              = var.ARM_PRIMARY_REGION
  account_tier          = "Standard"
  replication_type      = "LRS"
  container_name        = "primary-container-modular"
  container_access_type = "private"
}

module "azure_secondary_storage" {
  source                = "./modules/blob-storage"
  storage_account_name  = "secondarystorage${random_id.suffix.hex}"
  resource_group_name   = "secondary-blob-storage-${random_id.suffix.hex}"
  location              = var.ARM_SECONDARY_REGION
  account_tier          = "Standard"
  replication_type      = "LRS" 
  container_name        = "secondary-container-modular"
  container_access_type = "private"
}

# GCP storage modules
module "gcp_primary_storage" {
  source         = "./modules/gcs-storage"
  bucket_name    = "primary-storage-modular-${random_id.suffix.hex}"
  provider_alias = "primary"
  location       = var.GCP_PRIMARY_REGION
  storage_class  = "STANDARD"
  project        = var.GCP_PROJECT
}

module "gcp_secondary_storage" {
  source         = "./modules/gcs-storage"
  bucket_name    = "secondary-storage-modular-${random_id.suffix.hex}"
  provider_alias = "secondary"
  location       = var.GCP_SECONDARY_REGION
  storage_class  = "STANDARD"
  project        = var.GCP_PROJECT
}

# Random suffix para evitar conflitos de nomes
resource "random_id" "suffix" {
  byte_length = 4
}