variable "subnets" {
  description = "Modelo base para as subnets"
  type = list(object({
    az_suffix  = string  # Letra da Availability Zone
    cidr_index = number  # Último octeto do bloco CIDR (ex: 1 para 10.x.1.0/24)
  }))
  default = [
    { az_suffix = "a", cidr_index = 1 },
    { az_suffix = "b", cidr_index = 2 },
    { az_suffix = "c", cidr_index = 3 },
    { az_suffix = "d", cidr_index = 4 },
    { az_suffix = "e", cidr_index = 5 },
    { az_suffix = "f", cidr_index = 6 },
    { az_suffix = "g", cidr_index = 7 },
    { az_suffix = "h", cidr_index = 8 },
  ]
}

variable "vpcs" {
  description = "Configuração base das VPCs"
  type = map(object({
    region     = string
    cidr_base  = string  # Base do bloco CIDR (ex: "10.0" ou "10.1")
  }))
  default = {
    main = { region = "sa-east-1", cidr_base = "10.0" },
    backup  = { region = "us-east-1", cidr_base = "10.1" }
  }
}
