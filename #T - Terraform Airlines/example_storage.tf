variable "GCP_PROJECT" {}
variable "GCP_PRIMARY_REGION" {}
variable "GCP_SECONDARY_REGION" {}

# Configuração dos providers GCP com variáveis dinâmicas
provider "google" {
  alias   = "primary"
  project = var.GCP_PROJECT
  region  = var.GCP_PRIMARY_REGION

 # Configuração mágica que resolve todos os cenários:
  credentials = fileexists("${path.module}/.skip-creds") ? null : (
    var.GOOGLE_CREDENTIALS_B64 != null ? var.GOOGLE_CREDENTIALS : null
  )
}

provider "google" {
  alias   = "secondary"
  project = var.GCP_PROJECT
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
