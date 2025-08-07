# subnet_variables.tf
# Define as variáveis relacionadas às subnets, incluindo cores e blocos CIDR.

# Lista de cores que nomeiam as subnets, seguindo a ordem especificada (1 a 8).
variable "subnet_colors" {
  description = "Ordem e nomes das subnets baseadas em cores: red (1), green (2), ..., white (8)"
  type        = list(string)
  default     = ["red", "green", "blue", "yellow", "pink", "gold", "silver", "white"]
}

# Blocos CIDR para cada subnet (faixas /24 dentro do bloco da VPC).
# Exemplo: 10.0.1.0/24 (red), 10.0.2.0/24 (green), etc.
variable "subnet_cidr_blocks" {
  description = "Faixas de IPs para cada subnet, mapeadas para as cores na mesma ordem"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24",
                 "10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24"]
}
