output "firewall_rule_name" {
  description = "Nome da regra de Firewall criada"
  value       = google_compute_firewall.this.name
}