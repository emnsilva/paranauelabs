# ec2.tf
# Provisionamento de Computação (Instâncias EC2)
# Nas duas regiões: Primária (sa-east-1) e Secundária (us-east-1)

# FEATURE FLAGS (FinOps)
# Esta variável será injetada pelo pipeline do GitLab no futuro.
# Se ela for "true", a instância ganha a tag 'Schedule' e um 
# EventBridge a desligará fora do horário comercial para economizar.
variable "enable_auto_shutdown_compute" {
  description = "Feature Flag: Se true, adiciona tag para desligar a VM fora do horário comercial."
  type        = bool
  default     = false
}

# 1. COMPUTE REGIÃO PRIMÁRIA (sa-east-1)
# Busca a AMI mais recente do Amazon Linux 2023.
# Usar data sources garante que o código não quebre quando a AWS atualiza a imagem do sistema operacional.
data "aws_ami" "amazon_linux_primary" {
  provider    = aws.primary
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Cria a instância EC2.
resource "aws_instance" "compute_primary" {
  provider                    = aws.primary
  ami                         = data.aws_ami.amazon_linux_primary.id
  instance_type               = "t3.micro" # Tamanho econômico (Free Tier / FinOps)

  # Segurança: Colocamos na subnet privada e SEM IP público.
  subnet_id                   = aws_subnet.private_primary.id
  associate_public_ip_address = false

  # Segurança: Anexa o Security Group de Compute (que só permite SSH via SG Web).
  vpc_security_group_ids      = [aws_security_group.compute_primary.id]

  # Governança: Anexa a IAM Role criada no Card 9 (Least Privilege).
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile_primary.name

  # Script de inicialização (User Data). Apenas para validar que a máquina 
  # sobe e atualiza os pacotes base.
  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              EOF

  tags = {
    Name     = "ec2-primary-${var.environment}"
    # FinOps: Aplica a tag de scheduler condicionalmente via ternário do Terraform.
    Schedule = var.enable_auto_shutdown_compute ? "off-hours" : "always-on"
  }
}

# 2. COMPUTE REGIÃO SECUNDÁRIA (us-east-1)
# A mesma lógica, mas aplicada na região de Disaster Recovery (DR).
# Busca a AMI mais recente na região secundária
data "aws_ami" "amazon_linux_secondary" {
  provider    = aws.secondary
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"]
  }
}

# Cria a instância EC2 Secundária
resource "aws_instance" "compute_secondary" {
  provider                    = aws.secondary
  ami                         = data.aws_ami.amazon_linux_secondary.id
  instance_type               = "t3.micro"

  subnet_id                   = aws_subnet.private_secondary.id
  associate_public_ip_address = false

  vpc_security_group_ids      = [aws_security_group.compute_secondary.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile_secondary.name

  user_data = <<-EOF
              #!/bin/bash
              dnf update -y
              EOF

  tags = {
    Name     = "ec2-secondary-${var.environment}"
    Schedule = var.enable_auto_shutdown_compute ? "off-hours" : "always-on"
  }
}