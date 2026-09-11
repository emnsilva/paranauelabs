# compute.tf
# Provisionamento de Computação (Compute Instances)

data "google_compute_image" "debian" {
  family  = "debian-12"
  project = "debian-cloud"
}

# tfsec:ignore:google-compute-vm-disk-encryption-customer-key : KMS gerenciado pelo cliente custa $1/mês, default do Google atende ao lab.
resource "google_compute_instance" "vm_instance_primary" {
  name         = "vm-primary-${var.environment}"
  machine_type = "e2-micro"
  zone         = "${var.GCP_PRIMARY_REGION}-b"

  # Segurança exigida pelo tfsec (Shielded VM)
  shielded_instance_config {
    enable_vtpm = true
    enable_integrity_monitoring = true
  }

  # Segurança exigida pelo tfsec (Block Project SSH Keys)
  metadata = {
    block-project-ssh-keys = "TRUE"
  }

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

# tfsec:ignore:google-compute-vm-disk-encryption-customer-key : KMS gerenciado pelo cliente custa $1/mês, default do Google atende ao lab.
resource "google_compute_instance" "vm_instance_secondary" {
  name         = "vm-secondary-${var.environment}"
  machine_type = "e2-micro"
  zone         = "${var.GCP_SECONDARY_REGION}-b"

  # Segurança exigida pelo tfsec (Shielded VM)
  shielded_instance_config {
    enable_vtpm = true
    enable_integrity_monitoring = true
  }

  # Segurança exigida pelo tfsec (Block Project SSH Keys)
  metadata = {
    block-project-ssh-keys = "TRUE"
  }

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