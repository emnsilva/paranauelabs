# Cria buckets S3 em regiões primária e secundária

# Este bloco vazio diz: "Eu aceito qualquer configuração de provider"
terraform {}

# Bucket S3 primário
resource "aws_s3_bucket" "primary" {
  bucket        = "${var.PREFIXO_PROJETO}-${var.ENVIRONMENT}-primary"
  force_destroy = var.ENVIRONMENT == "dev" ? true : false
  tags          = var.TAGS_GLOBAIS
}

# Bucket S3 secundário
resource "aws_s3_bucket" "secondary" {
  provider      = aws.secondary
  bucket        = "${var.PREFIXO_PROJETO}-${var.ENVIRONMENT}-secondary"
  force_destroy = var.ENVIRONMENT == "dev" ? true : false
  tags          = var.TAGS_GLOBAIS
}

# Versionamento de objetos
resource "aws_s3_bucket_versioning" "versionamento" {
  for_each = {
    primary   = aws_s3_bucket.primary
    secondary = aws_s3_bucket.secondary
  }
  
  bucket = each.value.id
  versioning_configuration {
    status = var.habilitar_versionamento ? "Enabled" : "Suspended"
  }
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
  for_each = var.ENVIRONMENT == "production" && length(var.regras_lifecycle) > 0 ? {
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
