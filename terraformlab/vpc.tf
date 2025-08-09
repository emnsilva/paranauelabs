# Configura providers dinamicamente
provider "aws" {
  for_each = var.vpcs
  alias    = each.key  # "primary" ou "backup"
  region   = each.value.region
}

# Cria VPCs dinamicamente
resource "aws_vpc" "this" {
  for_each = var.vpcs

  provider             = aws[each.key]  # Usa o provider correspondente
  cidr_block          = each.value.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = each.value.vpc_name
  }
}
