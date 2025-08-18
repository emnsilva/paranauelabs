variable "GOOGLE_CREDENTIALS_B64" {
  type        = string
  default     = ""  # String vazia como padrão em vez de null
  description = "Credenciais em base64 (deixe vazio para usar OIDC)"
}

variable "GCP_PROJECT" {
  type        = string
  description = "ID do projeto GCP"
}

variable "GCP_PRIMARY_REGION" {}
variable "GCP_SECONDARY_REGION" {}

# Configuração do Provider Google
provider "google" {
  credentials = base64decode(var.GOOGLE_CREDENTIALS_B64)
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
