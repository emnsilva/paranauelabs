# Define quais "plugins" o Terraform precisa baixar e instalar
terraform {
  required_providers {
    # Provedor Google - Google Cloud Platform
    google = {
      source  = "hashicorp/google"  # Fonte oficial da HashiCorp
      version = "~> 7.35.0"         # Versão aproximadamente 7.35.0
    }
    # Provedor Random - Para gerar nomes únicos globais
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.0"
    }
  }
}

# Gerador de nome aleatório
# Cria um sufixo único para evitar conflitos de nomes globais do GCP
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Variáveis de configuração Google Cloud
# Define credenciais e regiões para o Google Cloud Platform
variable "GOOGLE_CREDENTIALS_B64" {
  default = null
  type    = string
}
variable "GCP_PROJECT" {}              # ID do projeto no Google Cloud
variable "GCP_PRIMARY_REGION" {}       # Região principal (ex: southamerica-east1)
variable "GCP_SECONDARY_REGION" {}     # Região secundária (ex: us-east1)

# Provedores Google Cloud
# Removemos o provider "padrão" sem alias para garantir o isolamento de região
provider "google" {
  alias       = "primary"
  project     = var.GCP_PROJECT
  region      = var.GCP_PRIMARY_REGION
  # Decodifica credenciais se fornecidas (base64 → texto normal)
  credentials = var.GOOGLE_CREDENTIALS_B64 != null ? base64decode(var.GOOGLE_CREDENTIALS_B64) : null
}

provider "google" {
  alias       = "secondary"
  project     = var.GCP_PROJECT
  region      = var.GCP_SECONDARY_REGION
  credentials = var.GOOGLE_CREDENTIALS_B64 != null ? base64decode(var.GOOGLE_CREDENTIALS_B64) : null
}

# Buckets Google Cloud Storage
# Cria "pastas gigantes" na nuvem do Google para armazenamento de objetos
# O nome precisa ser único globalmente, por isso usamos o sufixo aleatório
resource "google_storage_bucket" "primary" {
  name          = "primary-storage-${random_string.suffix.result}" # Nome único global
  provider      = google.primary
  location      = var.GCP_PRIMARY_REGION
  storage_class = "STANDARD"
}

resource "google_storage_bucket" "secondary" {
  name          = "secondary-storage-${random_string.suffix.result}" # Nome único global
  provider      = google.secondary # CORREÇÃO: Usando o provider correto da região secundária
  location      = var.GCP_SECONDARY_REGION
  storage_class = "STANDARD"
}