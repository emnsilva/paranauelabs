variable "GCP_PRIMARY_REGION" {}
variable "GCP_SECONDARY_REGION" {}

# Provider configurado para usar OIDC automaticamente no TFC
provider "google" {
  alias   = "primary"
  region  = var.GCP_PRIMARY_REGION
}

provider "google" {
  alias   = "secondary"
  region  = var.GCP_SECONDARY_REGION
}

# Recursos (nomes dinâmicos baseados nas variáveis)
resource "google_storage_bucket" "primary" {
  name          = "primary-storage"
  provider      = google.primary
  location      = var.GCP_PRIMARY_REGION
  storage_class = "STANDARD"
}

resource "google_storage_bucket" "secondary" {
  name          = "secondary-storage"
  provider      = google.primary
  location      = var.GCP_SECONDARY_REGION
  storage_class = "STANDARD"
}
