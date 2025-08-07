# subnets.tf: Subnets públicas numeradas de 1 a 8 em cada VPC

# Subnets na VPC Main (sa-east-1)
resource "aws_subnet" "main_public" {
  provider                = aws.main
  count                   = 8
  vpc_id                  = aws_vpc.main.id
  cidr_block              = cidrsubnet(var.vpcs["main"].cidr_block, 4, count.index)
  availability_zone       = "${var.vpcs["main"].region}${substr("abcdefgh", count.index, 1)}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${count.index + 1}"  # Numerando de 1 a 8
  }
}

# Subnets na VPC Backup (us-east-1) - Espelho exato
resource "aws_subnet" "backup_public" {
  provider                = aws.backup
  count                   = 8
  vpc_id                  = aws_vpc.backup.id
  cidr_block              = cidrsubnet(var.vpcs["backup"].cidr_block, 4, count.index)
  availability_zone       = "${var.vpcs["backup"].region}${substr("abcdefgh", count.index, 1)}"
  map_public_ip_on_launch = true

  tags = {
    Name = "${count.index + 1}"  # Numerando de 1 a 8
  }
}
