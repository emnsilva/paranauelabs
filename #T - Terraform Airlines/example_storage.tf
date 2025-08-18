variable "GCP_PROJECT" {
  description = "ID do projeto GCP"
  type        = string
}

variable "GCP_PRIMARY_REGION" {
  description = "Região primária (ex: us-central1)"
  type        = string
}

variable "GCP_SECONDARY_REGION" {
  description = "Região secundária (ex: us-east1)"
  type        = string
}

variable "GOOGLE_CREDENTIALS_B64" {
  description = "Credenciais em base64 (opcional para OIDC)"
  type        = string
  default     = null # Permite omitir quando usando OIDC
}

variable "USE_OIDC_AUTH" {
  description = "Ativar autenticação via OIDC"
  type        = bool
  default     = false
}

provider "google" {
  # Configuração dinâmica
  project     = var.GCP_PROJECT
  region      = var.GCP_PRIMARY_REGION
  
  # Usa OIDC se ativado, caso contrário usa credenciais tradicionais
  credentials = var.USE_OIDC_AUTH ? null : try(base64decode(var.GOOGLE_CREDENTIALS_B64), null)
  
  # Ativa OIDC quando necessário
  use_oidc    = var.USE_OIDC_AUTH
}

# Recursos (inalterados)
resource "google_storage_bucket" "primary" {
  name          = "${var.GCP_PROJECT}-bucket-${lower(var.GCP_PRIMARY_REGION)}"
  location      = var.GCP_PRIMARY_REGION
  storage_class = "STANDARD"
}

resource "google_storage_bucket" "secondary" {
  name          = "${var.GCP_PROJECT}-bucket-${lower(var.GCP_SECONDARY_REGION)}"
  location      = var.GCP_SECONDARY_REGION
  storage_class = "STANDARD"
}
