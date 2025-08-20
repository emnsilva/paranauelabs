# VARIÁVEIS DE CONFIGURAÇÃO
# Define as regiões AWS onde os buckets serão criados
# São como "configurações" que você precisa fornecer antes de executar
variable "AWS_REGION_PRIMARY" {}
variable "AWS_REGION_SECONDARY" {}

# PROVEDORES AWS
# Configura conexões com a AWS em duas regiões diferentes
# Cada provider é como um "canal de comunicação" com uma região específica
provider "aws" {
  alias  = "primary"                    # Apelido para referenciar este provider
  region = var.AWS_REGION_PRIMARY       # Usa a região definida na variável
}

provider "aws" {
  alias  = "secondary"                  # Apelido para referenciar este provider  
  region = var.AWS_REGION_SECONDARY     # Usa a região definida na variável
}

# BUCKETS S3
# Cria buckets de armazenamento em cada região
# São como "pastas gigantes" na nuvem da AWS para guardar arquivos
resource "aws_s3_bucket" "primary_bucket" {
  provider      = aws.primary           # Usa o provider da região primária
  bucket        = "primary-bucket"      # Nome único do bucket (⚠️ mude este nome)
  force_destroy = true                  # Permite deletar mesmo com arquivos dentro
}

resource "aws_s3_bucket" "secondary_bucket" {
  provider      = aws.secondary         # Usa o provider da região secundária
  bucket        = "secondary-bucket"    # Nome único do bucket (⚠️ mude este nome)
  force_destroy = true                  # Permite deletar mesmo com arquivos dentro
}
