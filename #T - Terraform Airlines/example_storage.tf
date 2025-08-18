variable "GCP_PROJECT" {}
variable "GCP_REGION_PRIMARY" {}
variable "GCP_REGION_SECONDARY" {}

# Provider único (OIDC ou credenciais automáticas)
provider "google" {
  project = var.GCP_PROJECT
  region  = var.GCP_REGION_PRIMARY
}

# Bucket na região primária
resource "google_storage_bucket" "primary" {
  name          = "${var.GCP_PROJECT}-primary-bucket"
  location      = var.GCP_REGION_PRIMARY
  storage_class = "STANDARD"
}

# Bucket na região secundária
resource "google_storage_bucket" "secondary" {
  name          = "${var.GCP_PROJECT}-secondary-bucket"
  location      = var.GCP_REGION_SECONDARY
  storage_class = "STANDARD"
}
