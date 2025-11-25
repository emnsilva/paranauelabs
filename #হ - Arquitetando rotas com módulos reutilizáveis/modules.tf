# modules.tf - Centralizando todas as chamadas de módulos da Terraform Airlines

# AWS storage modules
module "aws_primary_storage" {
  source         = "./modules/example-s3"
  bucket_name    = "primary-bucket"
  provider_alias = "primary"
  region         = var.AWS_REGION_PRIMARY
  force_destroy  = false
  tags = {
    Ambiente     = "production"
    Projeto      = "terraform-airlines"
    Componente   = "S3"
  }
}

module "aws_secondary_storage" {
  source         = "./modules/example-s3"
  bucket_name    = "secondary-bucket" 
  provider_alias = "secondary"
  region         = var.AWS_REGION_SECONDARY
  force_destroy  = true
  tags = {
    Ambiente     = "backup"
    Projeto      = "terraform-airlines"
    Componente   = "S3"
  }
}

# Azure storage modules
module "azure_primary_storage" {
  source                = "./modules/example-blob"
  storage_account_name  = "primarystorage"
  resource_group_name   = "primary-blob-storage"
  location              = var.ARM_PRIMARY_REGION
  account_tier          = "Standard"
  replication_type      = "LRS"
  container_name        = "primary-container-modular"
  container_access_type = "private"
}

module "azure_secondary_storage" {
  source                = "./modules/example-blob"
  storage_account_name  = "secondarystorage"
  resource_group_name   = "secondary-blob-storage"
  location              = var.ARM_SECONDARY_REGION
  account_tier          = "Standard"
  replication_type      = "LRS" 
  container_name        = "secondary-container-modular"
  container_access_type = "private"
}

# GCP storage modules
module "gcp_primary_storage" {
  source         = "./modules/example-storage"
  bucket_name    = "primary-storage-modular"
  provider_alias = "primary"
  location       = var.GCP_PRIMARY_REGION
  storage_class  = "STANDARD"
  project        = var.GCP_PROJECT
}

module "gcp_secondary_storage" {
  source         = "./modules/example-storage"
  bucket_name    = "secondary-storage-modular"
  provider_alias = "secondary"
  location       = var.GCP_SECONDARY_REGION
  storage_class  = "STANDARD"
  project        = var.GCP_PROJECT
}