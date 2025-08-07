# subnets.tf: Define 8 subnets públicas em cada VPC (main e backup)

# Cria 8 subnets públicas na VPC principal
resource "aws_subnet" "main" {
  provider                = aws.main
  count                   = 8
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpcs["main"].cidr_block, 4, count.index)
  availability_zone       = "${var.vpcs["main"].region}${element(["a", "b", "c", "d", "a", "b", "c", "d"], count.index)}"
  map_public_ip_on_launch = var.public_subnet_config.map_public_ip_on_launch

  tags = {
    Name = "${count.index + 1}"
  }
}

# Cria 8 subnets públicas na VPC de backup (espelho exato)
resource "aws_subnet" "backup" {
  provider                = aws.backup
  count                   = 8
  vpc_id                  = aws_vpc.backup.id
  cidr_block              = cidrsubnet(var.vpcs["backup"].cidr_block, 4, count.index) # Mesmos índices que main
  availability_zone       = "${var.vpcs["backup"].region}${element(["a", "b", "c", "d", "a", "b", "c", "d"], count.index)}"
  map_public_ip_on_launch = var.public_subnet_config.map_public_ip_on_launch

  tags = {
    Name = "${count.index + 1}"
  }
}