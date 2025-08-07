# subnets.tf
# Cria as subnets nas VPCs main e backup, usando as variáveis definidas em subnet_variables.tf.

# Subnets na VPC MAIN (região sa-east-1)
resource "aws_subnet" "main" {
  # Usa for_each para criar uma subnet por cor, mapeando cada cor ao seu índice (0 a 7).
  # Exemplo: red => 0 (10.0.1.0/24), green => 1 (10.0.2.0/24), etc.
  for_each = { for idx, color in var.subnet_colors : color => idx }

  provider = aws.main  # Usa o provider configurado para a região main (sa-east-1)
  vpc_id   = aws_vpc.main.id  # Associa à VPC main

  # Calcula o bloco CIDR da subnet: divide o bloco da VPC (10.0.0.0/16) em /24.
  # cidrsubnet(bloco_principal, novos_bits, número_da_subnet)
  cidr_block = cidrsubnet(var.vpcs["main"].cidr_block, 8, each.value + 1)

  # Define a zona de disponibilidade (ex: sa-east-1a).
  availability_zone = "${var.vpcs["main"].region}a"

  # Tags padrão:
  # - Name: Nome da subnet no formato "FWWC_2027_<cor>".
  # - Role: Tag opcional para filtrar subnets por cor (ex.: red, green).
  tags = {
    Name = "FWWC_2027_${each.key}"
    Role = each.key
  }
}

# Subnets na VPC BACKUP (região us-east-1) - mesma lógica da VPC main.
resource "aws_subnet" "backup" {
  for_each = { for idx, color in var.subnet_colors : color => idx }
  provider = aws.backup
  vpc_id   = aws_vpc.backup.id
  cidr_block = cidrsubnet(var.vpcs["backup"].cidr_block, 8, each.value + 1)
  availability_zone = "${var.vpcs["backup"].region}a"

  tags = {
    Name = "FWWC_2027_${each.key}"
    Role = each.key
  }
}
