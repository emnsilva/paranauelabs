# variables.tf
# Declaração das variáveis base do projeto.

variable "AWS_REGION_PRIMARY" {
  description = "Região primária da AWS onde os recursos principais serão provisionados."
  type        = string
  default     = "sa-east-1"
}

variable "AWS_REGION_SECONDARY" {
  description = "Região secundária da AWS para Disaster Recovery (DR)."
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Nome do ambiente (ex: dev, staging, prod). Injetado via pipeline."
  type        = string
  default     = "dev"
}