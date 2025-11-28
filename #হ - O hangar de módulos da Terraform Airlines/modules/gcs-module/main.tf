# main.tf - Lógica de criação do bucket GCS

terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.48.0"
    }
  }
}

resource "google_storage_bucket" "bucket" {
  provider      = google
  name          = var.bucket_name
  location      = var.location
  storage_class = var.storage_class
  force_destroy = var.force_destroy
  labels        = var.tags # No GCP, tags são chamadas de 'labels'
}