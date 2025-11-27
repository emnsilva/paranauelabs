variable "bucket_name" {
  description = "Nome único para o bucket GCS"
  type        = string
}

variable "provider_alias" {
  description = "Alias do provider GCP (primary/secondary)"
  type        = string
  default     = "primary"
}

variable "location" {
  description = "Região GCP onde o bucket será criado"
  type        = string
}

variable "storage_class" {
  description = "Classe de armazenamento (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "project" {
  description = "ID do projeto GCP"
  type        = string
}

variable "labels" {
  description = "Labels para organização e custos"
  type        = map(string)
  default     = {}
}