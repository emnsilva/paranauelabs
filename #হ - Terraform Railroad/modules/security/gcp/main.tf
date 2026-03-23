# 1. AS CANCELAS (Firewall Rule)
resource "google_compute_firewall" "this" {
  name    = "fw-${var.city_name}"
  network = var.vpc_name
  project = var.project_id

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
  labels        = var.tags
}