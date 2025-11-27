resource "google_storage_bucket" "secondary" {
  name          = var.bucket_name
  provider      = google.secondary
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