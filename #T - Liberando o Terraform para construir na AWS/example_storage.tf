# Configuração do Provider Google
provider "google" {
  credentials = var.GCP_CREDENTIALS
  project     = var.GCP_PROJECT
  region      = var.GCP_PRIMARY_REGION
}

# Bucket na região primária
resource "google_storage_bucket" "primary" {
  name          = "${var.GCP_PROJECT}-bucket-${lower(var.GCP_PRIMARY_REGION)}"
  location      = var.GCP_PRIMARY_REGION
  storage_class = "STANDARD"
}

# Bucket na região secundária
resource "google_storage_bucket" "secondary" {
  name          = "${var.GCP_PROJECT}-bucket-${lower(var.GCP_SECONDARY_REGION)}"
  location      = var.GCP_SECONDARY_REGION
  storage_class = "STANDARD"
}
