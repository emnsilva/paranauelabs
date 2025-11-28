output "bucket_url" {
  description = "URL do bucket GCS criado (gs://...)"
  value       = google_storage_bucket.bucket.url
}

output "bucket_name" {
  description = "Nome do bucket GCS criado"
  value       = google_storage_bucket.bucket.name
}

output "bucket_location" {
  description = "Localização do bucket GCS"
  value       = google_storage_bucket.bucket.location
}