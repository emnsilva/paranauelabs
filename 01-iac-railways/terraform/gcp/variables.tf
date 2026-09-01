# variables.tf
# Declaração das variáveis base do projeto no GCP.

variable "environment" {
  description = "Nome do ambiente (ex: dev, staging, prod). Injetado via pipeline."
  type        = string
  default     = "dev"
}

variable "GCP_REGION_PRIMARY" {
  description = "Região primária do GCP onde os recursos serão provisionados."
  type        = string
  default     = "southamerica-east1"
}

variable "GCP_REGION_SECONDARY" {
  description = "Região secundária do GCP para Disaster Recovery (DR)."
  type        = string
  default     = "us-east1"
}

variable "GCP_PROJECT_ID" {
  description = "ID do Projeto do GCP onde a infraestrutura será criada."
  type        = string
  default     = "ID do projeto" # Ajuste para o seu Project ID real
}

variable "BILLING_ACCOUNT_ID" {
  description = "ID da conta de faturamento do GCP para criação de Budgets."
  type        = string
  default     = "XXXXXX-XXXXXX-XXXXXX" # Substitua pelo ID da sua conta de billing
}