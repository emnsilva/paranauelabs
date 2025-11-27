output "primary_bucket_url" {
  description = "URL do bucket GCS primary"
  value       = try(google_storage_bucket.primary.url, null)
}

output "primary_bucket_name" {
  description = "Nome do bucket GCS primary"
  value       = try(google_storage_bucket.primary.name, null)
}

output "secondary_bucket_url" {
  description = "URL do bucket GCS secondary"
  value       = try(google_storage_bucket.secondary.url, null)
}

output "secondary_bucket_name" {
  description = "Nome do bucket GCS secondary"
  value       = try(google_storage_bucket.secondary.name, null)
}

output "all_buckets" {
  description = "Mapa com todos os buckets GCS"
  value = {
    primary = {
      url   = try(google_storage_bucket.primary.url, null)
      name  = try(google_storage_bucket.primary.name, null)
    }
    secondary = {
      url   = try(google_storage_bucket.secondary.url, null)
      name  = try(google_storage_bucket.secondary.name, null)
    }
  }
}