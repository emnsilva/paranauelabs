resource "google_storage_bucket" "primary" {
  name          = var.bucket_name
  provider      = google.primary
  location      = var.location
  storage_class = var.storage_class
  project       = var.project

  labels = merge(
    var.labels,
    {
      Module     = "gcs-storage"
      CreatedBy  = "terraform-airlines"
    }
  )
}