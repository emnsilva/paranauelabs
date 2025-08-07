# subnets_variables.tf: Configurações das subnets públicas

variable "public_subnet_config" {
  description = "Configuração comum para todas as subnets públicas"
  type = object({
    map_public_ip_on_launch = bool
  })
  default = {
    map_public_ip_on_launch = true
  }
}