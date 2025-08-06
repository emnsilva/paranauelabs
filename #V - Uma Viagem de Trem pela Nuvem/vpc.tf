# Configuração explícita dos providers
provider "aws" {
  alias  = "primary"
  region = var.vpcs["primary"].region
}

provider "aws" {
  alias  = "backup"
  region = var.vpcs["backup"].region
}

# Criação das VPCs com seleção direta de provider
resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block          = var.vpcs["primary"].cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}

resource "aws_vpc" "backup" {
  provider             = aws.backup
  cidr_block          = var.vpcs["backup"].cidr_block
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "backup"
  }
}
