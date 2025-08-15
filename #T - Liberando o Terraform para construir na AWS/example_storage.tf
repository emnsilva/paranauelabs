# Declarações OBRIGATÓRIAS (mesmo no Terraform Cloud)
variable "GOOGLE_CREDENTIALS_B64" {
  type        = string
  description = "Conteúdo do JSON da Service Account em Base64"
  sensitive   = true
}

variable "GCP_PROJECT_ID" {
  type        = string
  description = "ID do projeto no Google Cloud"
}

# Configuração do Provider
provider "google" {
  credentials = base64decode(var.GOOGLE_CREDENTIALS_B64)
  project     = var.GCP_PROJECT_ID
  region      = "southamerica-east1" # Região fixa (Brasil)
}

# Bucket no Brasil
resource "google_storage_bucket" "brasil" {
  name          = "${var.GCP_PROJECT_ID}-bucket-br" # Nome dinâmico
  location      = "southamerica-east1"
  storage_class = "STANDARD"
}
