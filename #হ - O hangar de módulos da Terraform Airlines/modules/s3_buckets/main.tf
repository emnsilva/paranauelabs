# Cria buckets S3 em regiões primária e secundária com configurações
# padronizadas e segurança embutida.

# Variáveis de configuração
# Define as regiões AWS onde os buckets serão criados
# São como "configurações" que você precisa fornecer antes de executar
variable "AWS_REGION_PRIMARY" {}
variable "AWS_REGION_SECONDARY" {}

# Este bloco vazio diz: "Eu aceito qualquer configuração de provider"
terraform {}

# Bucket S3 primário
resource "aws_s3_bucket" "primary" {
  bucket = "${var.prefixo_projeto}-${var.ambiente}-primary"
  force_destroy = var.ambiente == "dev" ? true : false
  tags = var.tags_globais
}

# Bucket S3 secundário
resource "aws_s3_bucket" "secondary" {
  provider = aws.secondary
  bucket = "${var.prefixo_projeto}-${var.ambiente}-secondary"
  force_destroy = var.ambiente == "dev" ? true : false
  tags = var.tags_globais  # ⬅️ APENAS TAGS GLOBAIS
}

# Versionamento de objetos
resource "aws_s3_bucket_versioning" "versionamento" {
  for_each = var.habilitar_versionamento ? {
    primary   = aws_s3_bucket.primary
    secondary = aws_s3_bucket.secondary
  } : {}
  
  bucket = each.value.id
  versioning_configuration { status = "Enabled" }
}

# Criptografia server-side
resource "aws_s3_bucket_server_side_encryption_configuration" "criptografia" {
  for_each = {
    primary   = aws_s3_bucket.primary
    secondary = aws_s3_bucket.secondary
  }
  
  bucket = each.value.id
  
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Políticas de lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "lifecycle" {
  for_each = length(var.regras_lifecycle) > 0 ? {
    primary   = aws_s3_bucket.primary
    secondary = aws_s3_bucket.secondary
  } : {}
  
  bucket = each.value.id
  
  dynamic "rule" {
    for_each = var.regras_lifecycle
    content {
      id     = rule.key
      status = "Enabled"
      expiration { days = rule.value.dias_expiracao }
      filter { prefix = rule.value.prefixo }
    }
  }
}