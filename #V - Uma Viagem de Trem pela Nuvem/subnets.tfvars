variable "vpcs" {
  description = "Dados das VPCs existentes"
  type = map(object({
    vpc_id     = string
    region     = string
    cidr_base  = string  # "10.0" para main, "10.1" para backup
  }))
}

variable "subnets" {
  description = "Configuração das 8 subnets públicas por VPC"
  type = list(object({
    az_suffix  = string  # "a", "b", "c", etc.
    cidr_index = number  # 1 a 8 (último octeto)
  }))
  default = [
  { az_suffix = "a", cidr_index = 1 },
  { az_suffix = "b", cidr_index = 2 },
  { az_suffix = "c", cidr_index = 3 },
  { az_suffix = "d", cidr_index = 4 },
  { az_suffix = "e", cidr_index = 5 },
  { az_suffix = "f", cidr_index = 6 },
  { az_suffix = "g", cidr_index = 7 },
  { az_suffix = "h", cidr_index = 8 }
  ]
}
