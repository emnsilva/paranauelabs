provider "google" {
  credentials = base64decode(var.GOOGLE_CREDENTIALS_B64)
  project     = var.gcp_project_id
  region      = var.gcp_primary_region  # Agora apontando para São Paulo
}

# Bucket na região primária (Brasil)
resource "google_storage_bucket" "primary" {
  name          = "${var.bucket_prefix}-primary"
  location      = var.gcp_primary_region  # southamerica-east1
  storage_class = "STANDARD"
}

# Bucket na região secundária (EUA)
resource "google_storage_bucket" "secondary" {
  name          = "${var.bucket_prefix}-secondary"
  location      = var.gcp_secondary_region  # us-east1
  storage_class = "STANDARD"
}
