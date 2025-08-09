variable "vpcs" {
  description = "Configuração das VPCs"
  type = map(object({
    region     = string
    cidr_block = string
    vpc_name   = string
  }))
  default = {
    primary = {
      region     = "sa-east-1",
      cidr_block = "10.0.0.0/16",
      vpc_name   = "main"
    },
    backup = {
      region     = "us-east-1",
      cidr_block = "10.1.0.0/16",
      vpc_name   = "backup"
    }
  }
}
