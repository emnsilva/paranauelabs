# s3.tf
# Provisionamento de Armazenamento (Cloud Storage Bucket)

# Bucket na Região Primária
resource "google_storage_bucket" "bucket_primary" {
  name          = "paranauelabs-iac-railways-${var.environment}-gcp-primary"
  location      = var.GCP_PRIMARY_REGION
  force_destroy = true

  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

# Bucket na Região Secundária
resource "google_storage_bucket" "bucket_secondary" {
  name          = "paranauelabs-iac-railways-${var.environment}-gcp-secondary"
  location      = var.GCP_SECONDARY_REGION
  force_destroy = true

  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}