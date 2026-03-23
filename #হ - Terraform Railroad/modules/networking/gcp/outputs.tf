# Exporta os dados da VPC e Subnet no GCP.
output "vpc_id" {
  description = "O ID da VPC Network"
  value       = google_compute_network.this.id
}

output "subnet_id" {
  description = "O ID da Subnet criada"
  value       = google_compute_subnetwork.this.id
}

output "subnet_cidr" {
  description = "O bloco CIDR da subnet"
  value       = google_compute_subnetwork.this.ip_cidr_range
}