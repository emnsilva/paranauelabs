# Exporta os identificadores da infraestrutura de rede criada.

output "vpc_id" {
  description = "O ID da VPC (Malha)"
  value       = aws_vpc.this.id
}

output "subnet_ids" {
  description = "Lista de IDs de todas as subnets (Trilhos)"
  # Concatena as listas padrão e extras em uma única lista limpa
  value       = concat(aws_subnet.standard[*].id, aws_subnet.hq_extra[*].id)
}