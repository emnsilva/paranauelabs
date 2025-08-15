# Configuração dos providers AWS com variáveis dinâmicas
provider "aws" {
  alias  = "primary"
  region = var.AWS_REGION_PRIMARY
}

provider "aws" {
  alias  = "secondary"
  region = var.AWS_REGION_SECONDARY
}

# Bucket na região primária
resource "aws_s3_bucket" "primary_bucket" {
  provider      = aws.primary
  bucket        = "primary-bucket"  # Substitua por um nome único global
  force_destroy = true  # Permite deletar o bucket mesmo com conteúdo (cuidado!)
}

# Bucket na região secundária
resource "aws_s3_bucket" "secondary_bucket" {
  provider      = aws.secondary
  bucket        = "secondary-bucket"  # Nome único global
  force_destroy = true
}
