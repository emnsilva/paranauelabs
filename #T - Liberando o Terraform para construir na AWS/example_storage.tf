# Configuração do Provider
provider "google" {
  credentials = base64decode(var.GOOGLE_CREDENTIALS_B64)
  project     = var.GCP_PROJECT_ID
  region      = local.region_mapping[var.CLOUD_PRIMARY_REGION].gcp
}

# Bucket no Brasil
resource "google_storage_bucket" "brasil" {
  name          = "${var.GCP_PROJECT_ID}-bucket-br"
  location      = local.region_mapping[var.CLOUD_PRIMARY_REGION].gcp
  storage_class = "STANDARD"
}

# Bucket nos USA
resource "google_storage_bucket" "usa" {
  name          = "${var.GCP_PROJECT_ID}-bucket-us"
  location      = local.region_mapping[var.CLOUD_SECONDARY_REGION].gcp
  storage_class = "STANDARD"
}
