variable "prefixo" {
  description = "Prefixo base para nomear resource groups e storages"
  type        = string
}

variable "ambiente" {
  description = "Ambiente (dev, staging, production)"
  type        = string
}

variable "primary_region" {
  description = "Região primária do Azure"
  type        = string
}

variable "secondary_region" {
  description = "Região secundária do Azure"
  type        = string
}

variable "tags_globais" {
  description = "Tags aplicadas a todos os recursos Azure"
  type        = map(string)
}

variable "tipo_conta" {
  description = "Tipo de conta de storage"
  type        = string
  default     = "Standard"
}

variable "tipo_replicacao" {
  description = "Tipo de replicação da storage account"
  type        = string
  default     = "LRS"
}

variable "nomes_containers" {
  description = "Lista de containers a serem criados em cada storage"
  type        = list(string)
  default     = ["app", "logs"]
}

variable "tipo_acesso_container" {
  description = "Tipo de acesso para os containers"
  type        = string
  default     = "private"
}

