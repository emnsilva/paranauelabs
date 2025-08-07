# Providers para cada região
provider "aws" {
  alias  = "main"
  region = var.vpc_data["main"].region
}

provider "aws" {
  alias  = "backup"
  region = var.vpc_data["backup"].region
}

# Subnets MAIN
resource "aws_subnet" "main" {
  count    = length(var.subnets)
  provider = aws.main

  vpc_id            = var.vpc_data["main"].vpc_id
  cidr_block        = "${var.vpc_data["main"].cidr_base}.${var.subnets[count.index].cidr_index}.0/24"
  availability_zone = "${var.vpc_data["main"].region}${var.subnets[count.index].az_suffix}"
  map_public_ip_on_launch = true  # Crucial para subnets públicas

  tags = {
    Name = "${var.subnets[count.index].az_suffix}"
  }
}

# Subnets BACKUP (idêntico, mas com provider e CIDR diferentes)
resource "aws_subnet" "backup" {
  count    = length(var.subnets)
  provider = aws.backup

  vpc_id            = var.vpc_data["backup"].vpc_id
  cidr_block        = "${var.vpc_data["backup"].cidr_base}.${var.subnets[count.index].cidr_index}.0/24"
  availability_zone = "${var.vpc_data["backup"].region}${var.subnets[count.index].az_suffix}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.subnets[count.index].az_suffix}"
  }
}
