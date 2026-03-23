# Define os insumos necessários para construir uma VPC (Malha Ferroviária) e suas subnets (Trilhos) na AWS.
# 1. Identificação
variable "city_name" {
  description = "Nome da cidade para identificação dos recursos"
  type        = string
}

# 2. Dimensionamento da Rede
variable "vpc_cidr" {
  description = "O bloco de IPs que define o tamanho da estação (ex: 10.0.0.0/16)"
  type        = string
}

variable "aws_region" {
  description = "A região AWS onde a via será construída"
  type        = string
}

# 3. Regras de Negócio
variable "is_headquarters" {
  description = "Interruptor: Se TRUE, ativa a construção de estruturas extras"
  type        = bool
  default     = false
}

# 4. Governança
variable "tags" {
  description = "Tags aplicadas em todos os recursos desta cidade"
  type        = map(string)
  default     = {}
}