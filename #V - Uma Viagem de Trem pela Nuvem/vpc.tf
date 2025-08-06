# vpc.tf: Contém toda a definição dos VPCs
# Configuração dinâmica de providers
provider "aws" {
  for_each = var.vpcs
  alias    = "${each.key}_region"
  region   = each.value.region
}

# Criação dinâmica de VPCs
resource "aws_vpc" "this" {
  for_each = var.vpcs

  provider             = aws["${each.key}_region"]
  cidr_block          = each.value.cidr_block
  enable_dns_support   = true    # Habilita suporte DNS
  enable_dns_hostnames = true    # Habilita hostnames DNS

  tags = {
    Name = each.key
  }
}
