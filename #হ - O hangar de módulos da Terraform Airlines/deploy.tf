# deploy.tf - Orquestrando todos os módulos da Terraform Airlines
# Provider AWS
provider "aws" {
  alias  = "primary"
  region = var.AWS_REGION_PRIMARY
}

provider "aws" {
  alias  = "secondary"
  region = var.AWS_REGION_SECONDARY
}

# Provider GCP
provider "google" {
  alias       = "primary"
  project     = var.GCP_PROJECT
  region      = var.GCP_PRIMARY_REGION
  credentials = base64decode(var.GOOGLE_CREDENTIALS_B64)
}

provider "google" {
  alias       = "secondary"
  project     = var.GCP_PROJECT
  region      = var.GCP_SECONDARY_REGION
  credentials = base64decode(var.GOOGLE_CREDENTIALS_B64)
}

# Provider Azure
provider "azurerm" {
  alias           = "primary"
  features {}
}

provider "azurerm" {
  alias           = "secondary"
  features {}
}


# Criação de recursos usando módulos
#Módulo s3

module "s3_primary_bucket" {
  source = "./modules/s3-module"

  # Passando o provedor explicitamente para o módulo
  providers = {
    aws = aws.primary
  }

  bucket_name   = "paranauelabs-bucket-primary-modular"
  force_destroy = true
  tags = {
    Environment = "Lab"
    Project     = "Terraform Airlines"
    Region      = "Primary"
  }
}

module "s3_secondary_bucket" {
  source = "./modules/s3-module"
  providers = {
    aws = aws.secondary
  }

  bucket_name   = "paranauelabs-bucket-secondary-modular"
  force_destroy = true
  tags = {
    Environment = "Lab"
    Project     = "Terraform Airlines"
    Region      = "Secondary"
  }
}

#Módulo GCS storage
module "gcs_primary_bucket" {
  source = "./modules/gcs-module"
  providers = {
    google = google.primary
  }

  bucket_name = "paranauelabs-gcs-primary-modular"
  location    = var.GCP_PRIMARY_REGION
  force_destroy = true
  tags = {
    environment = "lab"
    project     = "terraform-airlines"
    region      = "primary"
  }
}

module "gcs_secondary_bucket" {
  source = "./modules/gcs-module"
  providers = {
    google = google.secondary
  }

  bucket_name = "paranauelabs-gcs-secondary-modular"
  location    = var.GCP_SECONDARY_REGION
  force_destroy = true
  tags = {
    environment = "lab"
    project     = "terraform-airlines"
    region      = "secondary"
  }
}

#Módulo blob storage
module "blob_primary" {
  source = "./modules/blob-module"
  providers = {
    azurerm = azurerm.primary
  }

  location             = var.ARM_PRIMARY_REGION
  resource_group_name  = "paranauelabs-rg-primary-modular"
  storage_account_name = "paranauelabssaprimarymod"
  container_name       = "data"
  tags = {
    Environment = "Lab"
    Project     = "Terraform Airlines"
    Region      = "Primary"
  }
}

module "blob_secondary" {
  source = "./modules/blob-module"
  providers = {
    azurerm = azurerm.secondary
  }

  location             = var.ARM_SECONDARY_REGION
  resource_group_name  = "paranauelabs-rg-secondary-modular"
  storage_account_name = "paranauelabssasecondarymod"
  container_name       = "data"
  tags = {
    Environment = "Lab"
    Project     = "Terraform Airlines"
    Region      = "Secondary"
  }
}
