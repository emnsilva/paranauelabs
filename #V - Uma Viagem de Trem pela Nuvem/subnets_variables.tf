# subnets_variables.tf: Configurações comuns para subnets

variable "subnet_settings" {
  description = "Configurações padrão para todas as subnets"
  type = object({
    public_ip_on_launch = bool
  })
  default = {
    public_ip_on_launch = true
  }
}
