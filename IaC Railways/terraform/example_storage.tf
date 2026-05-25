# VARIÁVEIS DE CONFIGURAÇÃO GOOGLE CLOUD
# Define credenciais e regiões para o Google Cloud Platform
# A credencial pode vir codificada em base64 para maior segurança
variable "GOOGLE_CREDENTIALS_B64" {
  default = null  # Opcional - pode ser deixado em branco
}
variable "GCP_PROJECT" {}              # ID do projeto no Google Cloud
variable "GCP_PRIMARY_REGION" {}       # Região principal (ex: us-central1)
variable "GCP_SECONDARY_REGION" {}     # Região secundária (ex: europe-west1)

# PROVEDORES GOOGLE CLOUD
# Configura conexões com o GCP em regiões diferentes
# Cada provider acessa o mesmo projeto mas em regiões distintas
provider "google" {
  alias   = "primary"                   # Apelido para região primária
  project = var.GCP_PROJECT             # Projeto do Google Cloud
  region  = var.GCP_PRIMARY_REGION      # Região primária
  # Decodifica credenciais se fornecidas (base64 → texto normal)
  credentials = var.GOOGLE_CREDENTIALS_B64 != null ? base64decode(var.GOOGLE_CREDENTIALS_B64) : null
}

provider "google" {
  alias   = "secondary"                 # Apelido para região secundária
  project = var.GCP_PROJECT             # Mesmo projeto
  region  = var.GCP_SECONDARY_REGION    # Região secundária
}

# BUCKETS GOOGLE CLOUD STORAGE
# Cria buckets de armazenamento no Google Cloud
# Funcionam como containers para armazenar qualquer tipo de arquivo
resource "google_storage_bucket" "primary" {
  name          = "primary-storage"        # Nome do bucket
  provider      = google.primary           # Usa provider da região primária
  location      = var.GCP_PRIMARY_REGION   # Localização do bucket
  storage_class = "STANDARD"               # Classe de armazenamento (custo/desempenho)
}

resource "google_storage_bucket" "secondary" {
  name          = "secondary-storage"      # Nome do bucket
  provider      = google.primary           # ⚠️ Nota: usando provider primário
  location      = var.GCP_SECONDARY_REGION # Localização na região secundária
  storage_class = "STANDARD"               # Classe de armazenamento padrão
}
