provider "google" {
  credentials = var.GOOGLE_CREDENTIALS_B64  # Usa a variável do Terraform Cloud
  project     = var.GCP_PROJECT_ID      # Variável do workspace
  region      = "southamerica-east1"    # Hardcoded (ou use var.GCP_REGION se preferir)
}

# Bucket no Brasil
resource "google_storage_bucket" "brasil" {
  name          = "${var.BUCKET_PREFIX}-br"  # Nome dinâmico
  location      = "southamerica-east1"
  storage_class = "STANDARD"
}

# Bucket nos EUA
resource "google_storage_bucket" "eua" {
  name          = "${var.BUCKET_PREFIX}-us"
  location      = "us-east1"
  storage_class = "STANDARD"
}
