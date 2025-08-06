# vpc.tf: Contém toda a definição dos VPCs
# Configuração dinâmica de providers
provider "aws" {
  alias  = "primary_region"
  region = var.vpcs["primary"].region
}

provider "aws" {
  alias  = "backup_region"
  region = var.vpcs["backup"].region
}

# Criação DINÂMICA das VPCs (aqui sim usamos for_each)
resource "aws_vpc" "this" {
  for_each = var.vpcs

  provider = (
    each.key == "primary" 
    ? aws.primary_region 
    : aws.backup_region
  )

  cidr_block          = each.value.cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-${each.key}"
  }
}
