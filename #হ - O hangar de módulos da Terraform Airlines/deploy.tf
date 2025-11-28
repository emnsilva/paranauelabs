# deploy.tf - Orquestrando todos os módulos da Terraform Airlines

# Declaração das variáveis (os valores vêm do TFC)
variable "AWS_REGION_PRIMARY" {}
variable "AWS_REGION_SECONDARY" {}
variable "ARM_PRIMARY_REGION" {}
variable "ARM_SECONDARY_REGION" {}
variable "GCP_PRIMARY_REGION" {}
variable "GCP_SECONDARY_REGION" {}
variable "GCP_PROJECT" {}
variable "ARM_SUBSCRIPTION_ID" {
  default = "temp-fix"
}
variable "ARM_TENANT_ID" {
  default = "temp-fix"
}
variable "GOOGLE_CREDENTIALS_B64" {}

# Random suffix para evitar conflitos de nomes (coloque no TOPO)
resource "random_id" "suffix" {
  byte_length = 4
}

# AWS storage modules
module "aws_primary_storage" {
  source         = "./modules/s3-module"
  bucket_name    = "primary-bucket-${random_id.suffix.hex}"
  provider_alias = "primary"
  region         = var.AWS_REGION_PRIMARY
  force_destroy  = false
  tags = {
    Ambiente     = "production"
    Projeto      = "terraform-airlines"
    Componente   = "s3"
  }
}

module "aws_secondary_storage" {
  source         = "./modules/s3-module" 
  bucket_name    = "secondary-bucket-${random_id.suffix.hex}"
  provider_alias = "secondary"
  region         = var.AWS_REGION_SECONDARY
  force_destroy  = true
  tags = {
    Ambiente     = "backup"
    Projeto      = "terraform-airlines"
    Componente   = "s3"
  }
}

# Azure storage modules  
module "azure_primary_storage" {
  source                = "./modules/blob-module"
  storage_account_name  = "primarystor${random_id.suffix.hex}" # Azure requer nome sem hífen
  resource_group_name   = "primary-blob-storage-${random_id.suffix.hex}"
  location              = var.ARM_PRIMARY_REGION
  account_tier          = "Standard"
  replication_type      = "LRS"
  container_name        = "primary-container"
  container_access_type = "private"
}

module "azure_secondary_storage" {
  source                = "./modules/blob-module"
  storage_account_name  = "secondarystor${random_id.suffix.hex}" # Azure requer nome sem hífen
  resource_group_name   = "secondary-blob-storage-${random_id.suffix.hex}" 
  location              = var.ARM_SECONDARY_REGION
  account_tier          = "Standard"
  replication_type      = "LRS"
  container_name        = "secondary-container"
  container_access_type = "private"
}

# GCP storage modules
module "gcp_primary_storage" {
  source         = "./modules/gcs-module" 
  bucket_name    = "primary-storage-${random_id.suffix.hex}"
  provider_alias = "primary"
  location       = var.GCP_PRIMARY_REGION
  storage_class  = "STANDARD"
  project        = var.GCP_PROJECT
}

module "gcp_secondary_storage" {
  source         = "./modules/gcs-module"
  bucket_name    = "secondary-storage-${random_id.suffix.hex}"
  provider_alias = "secondary" 
  location       = var.GCP_SECONDARY_REGION
  storage_class  = "STANDARD"
  project        = var.GCP_PROJECT
}