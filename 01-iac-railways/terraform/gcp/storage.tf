# storage.tf
# Provisionamento de Armazenamento (Cloud Storage Bucket)

# tfsec:ignore:google-storage-bucket-encryption-customer-key : KMS gerenciado pelo cliente custa $1/mês, default do Google atende ao lab.
resource "google_storage_bucket" "bucket_primary" {
  name          = "paranauelabs-iac-railways-${var.environment}-gcp-primary"
  location      = lower(var.GCP_PRIMARY_REGION)
  force_destroy = true

  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}

# tfsec:ignore:google-storage-bucket-encryption-customer-key : KMS gerenciado pelo cliente custa $1/mês, default do Google atende ao lab.
resource "google_storage_bucket" "bucket_secondary" {
  name          = "paranauelabs-iac-railways-${var.environment}-gcp-secondary"
  location      = lower(var.GCP_SECONDARY_REGION)
  force_destroy = true

  uniform_bucket_level_access = true
  versioning {
    enabled = true
  }
}