# Módulo GCP - Buckets de Storage em duas regiões

variable "project_id" {
  description = "ID do projeto do GCP"
  type        = string
}

variable "primary_region" {
  description = "Região primária do GCP"
  type        = string
}

variable "secondary_region" {
  description = "Região secundária do GCP"
  type        = string
}

resource "google_storage_bucket" "primary" {
  name          = "terraform-airlines-primary-gcs"
  location      = var.primary_region
  storage_class = "STANDARD"
}

resource "google_storage_bucket" "secondary" {
  name          = "terraform-airlines-secondary-gcs"
  location      = var.secondary_region
  storage_class = "STANDARD"
}

output "primary_bucket_name" {
  description = "Nome do bucket primário no GCP"
  value       = google_storage_bucket.primary.name
}

output "secondary_bucket_name" {
  description = "Nome do bucket secundário no GCP"
  value       = google_storage_bucket.secondary.name
}
