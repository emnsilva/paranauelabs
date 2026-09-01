# network.tf
# Provisionamento da Rede (VPC Global, Subnets Regionais e Firewalls)

# Cria a VPC global
resource "google_compute_network" "vpc_network" {
  name                    = "vpc-${var.environment}"
  auto_create_subnetworks = false
}

# Subnet na Região PRIMÁRIA
resource "google_compute_subnetwork" "subnet_primary" {
  name          = "subnet-primary-${var.environment}"
  ip_cidr_range = "10.0.1.0/24"
  region        = var.GCP_REGION_PRIMARY
  network       = google_compute_network.vpc_network.id
}

# Subnet na Região SECUNDÁRIA (DR)
resource "google_compute_subnetwork" "subnet_secondary" {
  name          = "subnet-secondary-${var.environment}"
  ip_cidr_range = "10.1.1.0/24"
  region        = var.GCP_REGION_SECONDARY
  network       = google_compute_network.vpc_network.id
}


# Regras de Firewall

# Libera HTTP e HTTPS para a internet
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

# Libera SSH apenas para instâncias com a tag "web"
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