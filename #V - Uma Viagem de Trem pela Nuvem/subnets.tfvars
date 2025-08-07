# terraform.tfvars
# Arquivo para sobrescrever valores padrão das variáveis (usado em ambientes específicos).

# Configurações das VPCs:
vpcs = {
  main = {
    region     = "sa-east-1"    # Região principal (São Paulo)
    cidr_block = "10.0.0.0/16"  # Bloco principal da VPC (subnets serão /24 dentro deste)
  }
  backup = {
    region     = "us-east-1"    # Região de backup (N. Virginia)
    cidr_block = "10.1.0.0/16"  # Bloco da VPC de backup (não deve sobrepor à main)
  }
}

# Lista de cores e blocos CIDR para subnets (opcional: sobrescreve os defaults).
subnet_colors = ["red", "green", "blue", "yellow", "pink", "gold", "silver", "white"]
subnet_cidr_blocks = [
  "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24",
  "10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24"
]
