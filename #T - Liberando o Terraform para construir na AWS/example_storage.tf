# Declaração das variáveis (obrigatória mesmo usando Terraform Cloud)
variable "GOOGLE_CREDENTIALS_B64" {
  type        = string
  description = "Conteúdo do JSON da Service Account em Base64"
  sensitive   = true
}

variable "GCP_PROJECT_ID" {
  type        = string
  description = "ID do projeto no Google Cloud"
}

variable "BUCKET_PREFIX" {
  type        = string
  description = "Prefixo para nomear os buckets"
  default     = "paranaubucket"
}

# Configuração do Provider
provider "google" {
  credentials = base64decode(var.GOOGLE_CREDENTIALS_B64)
  project     = var.GCP_PROJECT_ID
  region      = "southamerica-east1"
}

# Bucket no Brasil
resource "google_storage_bucket" "brasil" {
  name          = "${var.BUCKET_PREFIX}-br"
  location      = "southamerica-east1"
  storage_class = "STANDARD"
}

# Bucket nos EUA
resource "google_storage_bucket" "eua" {
  name          = "${var.BUCKET_PREFIX}-us"
  location      = "us-east1"
  storage_class = "STANDARD"
}
