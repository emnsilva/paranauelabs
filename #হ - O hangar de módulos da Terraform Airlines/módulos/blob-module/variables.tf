variable "storage_account_name" {
  description = "Nome único global para a storage account (somente letras minúsculas e números)"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do resource group"
  type        = string
}

variable "location" {
  description = "Região Azure onde os recursos serão criados"
  type        = string
}

variable "account_tier" {
  description = "Tier da storage account (Standard/Premium)"
  type        = string
  default     = "Standard"
}

variable "replication_type" {
  description = "Tipo de replicação (LRS, GRS, ZRS)"
  type        = string
  default     = "LRS"
}

variable "container_name" {
  description = "Nome do container blob"
  type        = string
}

variable "container_access_type" {
  description = "Tipo de acesso do container (private, blob, container)"
  type        = string
  default     = "private"
}

variable "tags" {
  description = "Tags para organização e custos"
  type        = map(string)
  default     = {}
}