# network.tf
# Provisionamento da Rede (VPC, Subnets, IGW, Route Tables, SGs)
# Nas duas regiões: Primária (sa-east-1) e Secundária (us-east-1)

# 1. REDE REGIÃO PRIMÁRIA (sa-east-1)
# Cria a VPC principal. É a rede isolada onde todos os recursos da região primária vão ficar. 
# O DNS está ativado para que os recursos internos consigam se comunicar por nomes.
resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-primary-${var.environment}"
  }
}

# Cria o Internet Gateway (IGW). É a "porta de saída" da VPC para a internet pública. 
# Sem ele, os recursos não conseguem acessar a web nem ser acessados de fora.
resource "aws_internet_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  tags = {
    Name = "igw-primary-${var.environment}"
  }
}

# Cria a Subnet Pública. 
# Recursos criados aqui (como Load Balancers ou Bastions) recebem um IP público automaticamente 
# (map_public_ip_on_launch = true) para serem acessíveis pela internet.
resource "aws_subnet" "public_primary" {
  provider                  = aws.primary
  vpc_id                    = aws_vpc.primary.id
  cidr_block                = "10.0.1.0/24"
  availability_zone         = "sa-east-1a"
  map_public_ip_on_launch   = true

  tags = {
    Name = "subnet-public-primary-${var.environment}"
  }
}

# Cria a Subnet Privada. 
# Recursos criados aqui (como a instância EC2 do nosso laboratório) NÃO recebem IP público, ficando isolados da 
# internet direta. Isso aumenta drasticamente a segurança.
resource "aws_subnet" "private_primary" {
  provider          = aws.primary
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "subnet-private-primary-${var.environment}"
  }
}

# Cria a Tabela de Rotas (Route Table) pública. Ela diz à VPC: 
# "Qualquer tráfego que não seja interno (0.0.0.0/0) deve ser enviado para o Internet Gateway".
resource "aws_route_table" "public_primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary.id
  }

  tags = {
    Name = "rt-public-primary-${var.environment}"
  }
}

# Associa a Tabela de Rotas pública à Subnet Pública. 
# É isso que efetivamente "liga a internet" na subnet pública.
resource "aws_route_table_association" "public_primary" {
  provider       = aws.primary
  subnet_id      = aws_subnet.public_primary.id
  route_table_id = aws_route_table.public_primary.id
}

# SECURITY GROUPS (Região Primária)
# Seguindo o princípio de Least Privilege (ADR-002)
# Security Group Web: Atua como a "porta da frente". Libera as portas 80 (HTTP) e 443 (HTTPS) para qualquer pessoa na internet acessar.
# Saída (egress) totalmente liberada para a máquina poder baixar atualizações.
resource "aws_security_group" "web_primary" {
  provider    = aws.primary
  name        = "secgroup-web-primary-${var.environment}"
  description = "Permite trafego HTTP e HTTPS de entrada"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secgroup-web-primary-${var.environment}"
  }
}

# Security Group Compute: Atua como a "porta dos fundos". É onde a EC2 vai ficar. 
# NUNCA liberamos SSH (porta 22) para a internet (0.0.0.0/0).
# Em vez disso, o SSH só é permitido se vier de um recurso que está dentro do Security Group Web. Isso é chamado de referência cruzada.
resource "aws_security_group" "compute_primary" {
  provider    = aws.primary
  name        = "secgroup-compute-primary-${var.environment}"
  description = "Permite SSH apenas do SG Web"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description     = "SSH vindo do SG Web"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_primary.id] # Referência direta!
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secgroup-compute-primary-${var.environment}"
  }
}

# 2. REDE REGIÃO SECUNDÁRIA (us-east-1)
# A mesma lógica da primária, mas usando o provider "secondary" e blocos CIDR diferentes (10.1.x.x). 
# Usar CIDRs diferentes é obrigatório caso queiramos conectar as duas VPCs no futuro (VPC Peering).

# VPC Secundária
resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-secondary-${var.environment}"
  }
}

# Internet Gateway Secundário
resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  tags = {
    Name = "igw-secondary-${var.environment}"
  }
}

# Subnet Pública Secundária
resource "aws_subnet" "public_secondary" {
  provider                  = aws.secondary
  vpc_id                    = aws_vpc.secondary.id
  cidr_block                = "10.1.1.0/24"
  availability_zone         = "us-east-1a"
  map_public_ip_on_launch   = true

  tags = {
    Name = "subnet-public-secondary-${var.environment}"
  }
}

# Subnet Privada Secundária
resource "aws_subnet" "private_secondary" {
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-private-secondary-${var.environment}"
  }
}

# Tabela de Rotas Pública Secundária
resource "aws_route_table" "public_secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary.id
  }

  tags = {
    Name = "rt-public-secondary-${var.environment}"
  }
}

# Associação da Tabela de Rotas Pública Secundária
resource "aws_route_table_association" "public_secondary" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.public_secondary.id
  route_table_id = aws_route_table.public_secondary.id
}

# Security Group Web Secundário
resource "aws_security_group" "web_secondary" {
  provider    = aws.secondary
  name        = "secgroup-web-secondary-${var.environment}"
  description = "Permite trafego HTTP e HTTPS de entrada"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secgroup-web-secondary-${var.environment}"
  }
}

# Security Group Compute Secundário
resource "aws_security_group" "compute_secondary" {
  provider    = aws.secondary
  name        = "secgroup-compute-secondary-${var.environment}"
  description = "Permite SSH apenas do SG Web"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    description     = "SSH vindo do SG Web"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_secondary.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "secgroup-compute-secondary-${var.environment}"
  }
}