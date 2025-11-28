variable "bucket_name" {
  description = "Nome único global para o bucket GCS."
  type        = string
}

variable "location" {
  description = "Região GCP onde o bucket será criado."
  type        = string
}

variable "storage_class" {
  description = "Classe de armazenamento (STANDARD, NEARLINE, COLDLINE, ARCHIVE)"
  type        = string
  default     = "STANDARD"
}

variable "force_destroy" {
  description = "Forçar destruição do bucket mesmo com objetos internos."
  type        = bool
  default     = false
}

variable "tags" {
  description = "Labels para organização e custos"
  type        = map(string)
  default     = {}
}