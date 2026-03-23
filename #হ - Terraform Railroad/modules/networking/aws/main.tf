# 1. A MALHA FERROVIÁRIA (VPC)
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = merge(var.tags, {
    Name = "VPC-${var.city_name}"
  })
}

# 2. TRILHOS PADRÃO (Subnets)
# Cria 3 trilhos básicos para qualquer cidade.
resource "aws_subnet" "standard" {
  count             = 3
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index)
  availability_zone = "${var.aws_region}a"
  tags = merge(var.tags, {
    Name = "Subnet-${count.index + 1}-${var.city_name}"
  })
}

# 3. TRILHOS EXCLUSIVOS DA SEDE (Condicional)
# A lógica da "Bitola Universal": Se for Sede, cria mais trilhos.
resource "aws_subnet" "hq_extra" {
  count = var.is_headquarters ? 3 : 0
  vpc_id            = aws_vpc.this.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 8, count.index + 10)
  availability_zone = "${var.aws_region}b"
  tags = merge(var.tags, {
    Name = "Subnet-HQ-${count.index + 1}-${var.city_name}"
  })
}