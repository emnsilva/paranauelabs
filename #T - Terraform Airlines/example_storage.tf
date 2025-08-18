variable "GCP_PROJECT" {}
variable "GCP_PRIMARY_REGION" {}
variable "GCP_SECONDARY_REGION" {}

# Provider configurado para usar OIDC automaticamente no TFC
provider "google" {
  project = var.GCP_PROJECT
  region  = var.GCP_PRIMARY_REGION
}

# Recursos (nomes dinâmicos baseados nas variáveis)
resource "google_storage_bucket" "primary" {
  name          = "${var.GCP_PROJECT}-primary-${var.GCP_PRIMARY_REGION}"
  location      = var.GCP_PRIMARY_REGION
  storage_class = "STANDARD"
}

resource "google_storage_bucket" "secondary" {
  name          = "${var.GCP_PROJECT}-secondary-${var.GCP_SECONDARY_REGION}"
  location      = var.GCP_SECONDARY_REGION
  storage_class = "STANDARD"
}
