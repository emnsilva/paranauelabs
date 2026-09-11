# network.tf
# Provisionamento da Rede (VPC Global, Subnets Regionais e Firewalls)

# Cria a VPC global
resource "google_compute_network" "vpc_network" {
  name                    = "vpc-${var.environment}"
  auto_create_subnetworks = false
}

# tfsec:ignore:google-compute-enable-vpc-flow-logs : Laboratório sem faturamento ativo, Flow Logs geram custos.
resource "google_compute_subnetwork" "subnet_primary" {
  name          = "subnet-primary-${var.environment}"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.GCP_PRIMARY_REGION
  network       = google_compute_network.vpc_network.id
}

# tfsec:ignore:google-compute-enable-vpc-flow-logs : Laboratório sem faturamento ativo, Flow Logs geram custos.
resource "google_compute_subnetwork" "subnet_secondary" {
  name          = "subnet-secondary-${var.environment}"
  ip_cidr_range = "10.1.1.0/24"
  region        = var.GCP_SECONDARY_REGION
  network       = google_compute_network.vpc_network.id
}

# FIREWALL RULES (São globais, valem para as duas regiões)
# tfsec:ignore:google-compute-no-public-ingress : Laboratório requer acesso HTTP/HTTPS público ao servidor Web.
resource "google_compute_firewall" "web_rules" {
  name    = "fw-web-${var.environment}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["80", "443"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["web"]
}

resource "google_compute_firewall" "ssh_internal" {
  name    = "fw-ssh-internal-${var.environment}"
  network = google_compute_network.vpc_network.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_tags = ["web"]
  target_tags = ["compute"]
}