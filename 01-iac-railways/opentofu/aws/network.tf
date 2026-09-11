# network.tf
# Provisionamento da Rede (VPC, Subnets, IGW, Route Tables, SGs)
# Nas duas regiões: Primária (sa-east-1) e Secundária (us-east-1)

# 1. Rede Primária (sa-east-1)
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs : Laboratório sem faturamento ativo, Flow Logs geram custos.
resource "aws_vpc" "primary" {
  provider             = aws.primary
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-primary-${var.environment}"
  }
}

resource "aws_internet_gateway" "primary" {
  provider = aws.primary
  vpc_id   = aws_vpc.primary.id

  tags = {
    Name = "igw-primary-${var.environment}"
  }
}

# tfsec:ignore:aws-ec2-no-public-ip-subnet : Subnet pública proposital para futuros Load Balancers/Bastions.
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

resource "aws_subnet" "private_primary" {
  provider          = aws.primary
  vpc_id            = aws_vpc.primary.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "sa-east-1a"

  tags = {
    Name = "subnet-private-primary-${var.environment}"
  }
}

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

resource "aws_route_table_association" "public_primary" {
  provider       = aws.primary
  subnet_id      = aws_subnet.public_primary.id
  route_table_id = aws_route_table.public_primary.id
}

# Security Groups Primária (Least Privilege)
resource "aws_security_group" "web_primary" {
  provider    = aws.primary
  name        = "web-sg-primary-${var.environment}"
  description = "Permite trafego HTTP e HTTPS de entrada"
  vpc_id      = aws_vpc.primary.id

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr : Laboratório requer acesso HTTP público ao servidor Web.
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr : Laboratório requer acesso HTTPS público ao servidor Web.
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr : Laboratório permite saída de internet para updates da VM.
  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg-primary-${var.environment}"
  }
}

resource "aws_security_group" "compute_primary" {
  provider    = aws.primary
  name        = "compute-sg-primary-${var.environment}"
  description = "Permite SSH apenas do SG Web"
  vpc_id      = aws_vpc.primary.id

  ingress {
    description     = "SSH vindo do SG Web"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_primary.id] # Referência direta!
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr : Laboratório permite saída de internet para updates da VM.
  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "compute-sg-primary-${var.environment}"
  }
}

# 2. Região Secundária (us-east-1)
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs : Laboratório sem faturamento ativo, Flow Logs geram custos.
resource "aws_vpc" "secondary" {
  provider             = aws.secondary
  cidr_block           = "10.1.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "vpc-secondary-${var.environment}"
  }
}

resource "aws_internet_gateway" "secondary" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary.id

  tags = {
    Name = "igw-secondary-${var.environment}"
  }
}

# tfsec:ignore:aws-ec2-no-public-ip-subnet : Subnet pública proposital para futuros Load Balancers/Bastions.
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

resource "aws_subnet" "private_secondary" {
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "subnet-private-secondary-${var.environment}"
  }
}

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

resource "aws_route_table_association" "public_secondary" {
  provider       = aws.secondary
  subnet_id      = aws_subnet.public_secondary.id
  route_table_id = aws_route_table.public_secondary.id
}

# Security Groups Secundária (Least Privilege)
resource "aws_security_group" "web_secondary" {
  provider    = aws.secondary
  name        = "web-sg-secondary-${var.environment}"
  description = "Permite trafego HTTP e HTTPS de entrada"
  vpc_id      = aws_vpc.secondary.id

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr : Laboratório requer acesso HTTP público ao servidor Web.
  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tfsec:ignore:aws-ec2-no-public-ingress-sgr : Laboratório requer acesso HTTPS público ao servidor Web.
  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr : Laboratório permite saída de internet para updates da VM.
  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web-sg-secondary-${var.environment}"
  }
}

resource "aws_security_group" "compute_secondary" {
  provider    = aws.secondary
  name        = "compute-sg-secondary-${var.environment}"
  description = "Permite SSH apenas do SG Web"
  vpc_id      = aws_vpc.secondary.id

  ingress {
    description     = "SSH vindo do SG Web"
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.web_secondary.id] # Referência direta!
  }

  # tfsec:ignore:aws-ec2-no-public-egress-sgr : Laboratório permite saída de internet para updates da VM.
  egress {
    description = "Allow all egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "compute-sg-secondary-${var.environment}"
  }
}