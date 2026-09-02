# iam.tf
# Provisionamento de Identidade e Acesso (IAM)

# Cria a Service Account que as VMs vão usar
resource "google_service_account" "vm_sa" {
  account_id   = "vm-sa-${var.environment}"
  display_name = "Service Account para VM ${var.environment}"
}

# Permissão para o Bucket Primário
resource "google_storage_bucket_iam_member" "vm_sa_bucket_access_primary" {
  bucket = google_storage_bucket.bucket_primary.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vm_sa.email}"
}

# Permissão para o Bucket Secundário
resource "google_storage_bucket_iam_member" "vm_sa_bucket_access_secondary" {
  bucket = google_storage_bucket.bucket_secondary.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.vm_sa.email}"
}