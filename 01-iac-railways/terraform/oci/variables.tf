variable "environment" {
  description = "Nome do ambiente (ex: dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "tenancy_ocid" {
  description = "OCID da Tenancy da Oracle"
  type        = string
  sensitive   = true
}

variable "user_ocid" {
  description = "OCID do User da Oracle"
  type        = string
  sensitive   = true
}

variable "fingerprint" {
  description = "Fingerprint da API Key"
  type        = string
  sensitive   = true
}

variable "private_key" {
  description = "Chave privada da API Key"
  type        = string
  sensitive   = true
}

variable "region" {
  description = "Região da Oracle Cloud"
  type        = string
  default     = "sa-saopaulo-1"
}