variable "resource_group_name" {
  description = "Nome do Resource Group (vem do módulo de rede)"
  type        = string
}

variable "location" {
  description = "Região Azure"
  type        = string
}

variable "subnet_ids" {
  description = "Lista de IDs das Subnets onde aplicar as regras"
  type        = list(string)
}

variable "city_name" {
  type = string
}

variable "tags" {
  type        = map(string)
  default     = {}
}