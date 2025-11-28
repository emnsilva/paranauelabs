# variables.tf - Especificações do módulo Azure Blob Storage

variable "location" {
  description = "Região do Azure onde os recursos serão criados."
  type        = string
}

variable "resource_group_name" {
  description = "Nome do Resource Group."
  type        = string
}

variable "storage_account_name" {
  description = "Nome único global para a Storage Account (letras minúsculas e números)."
  type        = string
}

variable "container_name" {
  description = "Nome do container dentro da Storage Account."
  type        = string
}

variable "account_tier" {
  description = "Tier da Storage Account (Standard ou Premium)."
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Tipo de replicação da Storage Account (ex: LRS, GRS)."
  type        = string
  default     = "LRS"
}

variable "container_access_type" {
  description = "Nível de acesso do container (ex: private, blob, container)."
  type        = string
  default     = "private"
}

variable "tags" {
  description = "Tags para organização e custos."
  type        = map(string)
  default     = {}
}