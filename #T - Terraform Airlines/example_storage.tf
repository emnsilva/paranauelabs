variable "GCP_PRIMARY_REGION" {}
variable "GCP_SECONDARY_REGION" {}

# Configuração dos providers GCP com variáveis dinâmicas
provider "google" {
  alias   = "primary"
  region  = var.GCP_PRIMARY_REGION
}

provider "google" {
  alias   = "secondary"
  region  = var.GCP_SECONDARY_REGION
}

# Storage na região primária
resource "google_storage_bucket" "primary" {
  name          = "primary-storage"
  provider      = google.primary
  location      = var.GCP_PRIMARY_REGION
  storage_class = "STANDARD"
}

# Storage na região secundária
resource "google_storage_bucket" "secondary" {
  name          = "secondary-storage"
  provider      = google.primary
  location      = var.GCP_SECONDARY_REGION
  storage_class = "STANDARD"
}
