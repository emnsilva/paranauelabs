# Variáveis compatíveis com seus Variable Sets existentes
variable "GCP_PROJECT" {
  description = "ID do projeto GCP (definido no Variable Set)"
  type        = string
}

variable "GCP_PRIMARY_REGION" {
  description = "Região primária (definida no Variable Set)"
  type        = string
  default     = "us-central1" # Fallback seguro
}

variable "GCP_SECONDARY_REGION" {
  description = "Região secundária (definida no Variable Set)"
  type        = string
  default     = "us-east1" # Fallback seguro
}

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
