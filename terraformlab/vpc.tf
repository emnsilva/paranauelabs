# Configuração explícita dos providers
provider "aws" {
  alias  = "primary"
  region = var.vpcs["primary"].region
}

provider "aws" {
  alias  = "backup"
  region = var.vpcs["backup"].region
}

# Criação dinâmica das VPCs usando count
resource "aws_vpc" "this" {
  count = length(var.vpcs)

  provider = count.index == 0 ? aws.primary : aws.backup
  cidr_block = values(var.vpcs)[count.index].cidr_block
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = values(var.vpcs)[count.index].vpc_name
  }
}
