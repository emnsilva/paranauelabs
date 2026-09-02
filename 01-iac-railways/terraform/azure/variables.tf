# variables.tf
# Declaração das variáveis base do projeto.

variable "environment" {
  description = "Nome do ambiente (ex: dev, staging, prod). Injetado via pipeline."
  type        = string
  default     = "dev"
}

variable "AZURE_PRIMARY_REGION" {
  description = "Região primária do Azure onde os recursos serão provisionados."
  type        = string
  default     = "brazilsouth"
}

variable "AZURE_SECONDARY_REGION" {
  description = "Região secundária do Azure para Disaster Recovery (DR)."
  type        = string
  default     = "eastus"
}