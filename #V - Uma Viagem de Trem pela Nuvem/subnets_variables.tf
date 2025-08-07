# subnet_variables.tf
variable "subnet_colors" {
  description = "Ordem e nomes das subnets baseadas em cores"
  type        = list(string)
  default     = ["red", "green", "blue", "yellow", "pink", "gold", "silver", "white"]
}

variable "subnet_cidr_blocks" {
  description = "Faixas de IPs para cada subnet (8 blocos /24 por VPC)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24",
                 "10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24"]
}
