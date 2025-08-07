# subnets.tf
# Subnets para a VPC MAIN (sa-east-1)
resource "aws_subnet" "main" {
  for_each          = { for idx, color in var.subnet_colors : color => idx }
  provider          = aws.main
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpcs["main"].cidr_block, 8, each.value + 1)  # 10.0.1.0/24, 10.0.2.0/24...
  availability_zone = "${var.vpcs["main"].region}a"

  tags = {
    Name = "{each.key}"
    Role = each.key
  }
}

# Subnets para a VPC BACKUP (us-east-1)
resource "aws_subnet" "backup" {
  for_each          = { for idx, color in var.subnet_colors : color => idx }
  provider          = aws.backup
  vpc_id            = aws_vpc.backup.id
  cidr_block        = cidrsubnet(var.vpcs["backup"].cidr_block, 8, each.value + 1)  # 10.1.1.0/24, 10.1.2.0/24...
  availability_zone = "${var.vpcs["backup"].region}a"

  tags = {
    Name = "{each.key}"
    Role = each.key
  }
}
