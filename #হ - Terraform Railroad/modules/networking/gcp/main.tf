# 1. A MALHA GLOBAL (VPC Network)
resource "google_compute_network" "this" {
  name                    = "vpc-${var.city_name}"
  auto_create_subnetworks = false
  project                 = var.project_id
}

# 2. TRILHOS PADRÃO (Subnetwork)
resource "google_compute_subnetwork" "standard" {
  count         = 2
  name          = "subnet-padrao-${count.index + 1}"
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, count.index)
  region        = var.region
  network       = google_compute_network.this.id
  project       = var.project_id
}

# 3. TRILHOS EXCLUSIVOS DA SEDE (Condicional)
# Lógica idêntica: expande a capacidade se for sede.
resource "google_compute_subnetwork" "hq_extra" {
  count         = var.is_headquarters ? 2 : 0
  name          = "subnet-sede-extra-${count.index + 1}"
  ip_cidr_range = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  region        = var.region
  network       = google_compute_network.this.id
  project       = var.project_id
}