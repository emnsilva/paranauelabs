# 1. Onde instalar (Recebe do módulo de Networking)
variable "vpc_id" {
  description = "O ID da VPC onde as cancelas serão instaladas"
  type        = string
}

# 2. Regras de Tráfego
variable "allowed_ports" {
  description = "Lista de portas que serão liberadas no firewall"
  type        = list(number)
  default     = [80, 443]
}

# 3. Identificação
variable "city_name" {
  description = "Nome da cidade para tags"
  type        = string
}

variable "tags" {
  description = "Tags do recurso"
  type        = map(string)
  default     = {}
}