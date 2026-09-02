# compute.tf
# Provisionamento de Computação (VM Instance)

data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

# VM na Região PRIMÁRIA
resource "google_compute_instance" "vm_instance_primary" {
  name         = "vm-primary-${var.environment}"
  machine_type = "e2-micro"
  zone         = "${var.GCP_PRIMARY_REGION}-b"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_primary.id
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["compute"]
}

# VM na Região SECUNDÁRIA (DR)
resource "google_compute_instance" "vm_instance_secondary" {
  name         = "vm-secondary-${var.environment}"
  machine_type = "e2-micro"
  zone         = "${var.GCP_SECONDARY_REGION}-b"

  boot_disk {
    initialize_params {
      image = data.google_compute_image.debian.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.subnet_secondary.id
  }

  service_account {
    email  = google_service_account.vm_sa.email
    scopes = ["cloud-platform"]
  }

  tags = ["compute"]
}