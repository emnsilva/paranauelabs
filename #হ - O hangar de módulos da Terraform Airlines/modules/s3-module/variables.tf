# variables.tf - Especificações do módulo S3 Storage

variable "bucket_name" {
  description = "Nome único para o bucket S3"
  type        = string
  validation {
    condition     = can(regex("^[a-z0-9.-]{3,63}$", var.bucket_name))
    error_message = "Nome do bucket deve ter entre 3-63 caracteres (letras minúsculas, números, hífens e pontos)."
  }
}

variable "provider_alias" {
  description = "Alias do provider AWS (primary/secondary) - deve corresponder aos providers configurados no root module"
  type        = string
  default     = "primary"
}

variable "region" {
  description = "Região AWS onde o bucket será criado - use var.AWS_REGION_PRIMARY ou var.AWS_REGION_SECONDARY do Terraform Cloud"
  type        = string
}

variable "force_destroy" {
  description = "Forçar destruição do bucket mesmo com objetos internos (use com cautela em produção)"
  type        = bool
  default     = false
}

variable "tags" {
  description = "Tags para organização e custos"
  type        = map(string)
  default     = {}
}