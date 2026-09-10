# s3.tf
# Provisionamento de Armazenamento (Buckets S3)
# Nas duas regiões: Primária (sa-east-1) e Secundária (us-east-1)

# 1. Região Primária (sa-east-1)
# Cria o Bucket S3 na região primária.
resource "aws_s3_bucket" "primary" {
  # tfsec:ignore:aws-s3-enable-bucket-logging : Logging exige criação de um segundo bucket de logs, fora do escopo do laboratório.
  provider = aws.primary
  bucket   = local.s3_bucket_name_primary

  tags = {
    Name = local.s3_bucket_name_primary
  }
}

# Configuração de Segurança: Bloqueia TODO o acesso público ao bucket.
resource "aws_s3_bucket_public_access_block" "primary" {
  provider                = aws.primary
  bucket                  = aws_s3_bucket.primary.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configuração de Segurança: Ativa a criptografia em repouso (SSE-S3).
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      # tfsec:ignore:aws-s3-encryption-customer-key : KMS gerenciado pelo cliente custa $1/mês, SSE-S3 (gratuito) atende ao lab.
      sse_algorithm = "AES256"
    }
  }
}

# Governança: Ativa o versionamento do bucket.
resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 2. Região Secundária (us-east-1)
# A mesma lógica de segurança, mas na região de DR.
resource "aws_s3_bucket" "secondary" {
  # tfsec:ignore:aws-s3-enable-bucket-logging : Logging exige criação de um segundo bucket de logs, fora do escopo do laboratório.
  provider = aws.secondary
  bucket   = local.s3_bucket_name_secondary

  tags = {
    Name = local.s3_bucket_name_secondary
  }
}

resource "aws_s3_bucket_public_access_block" "secondary" {
  provider                = aws.secondary
  bucket                  = aws_s3_bucket.secondary.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id

  rule {
    apply_server_side_encryption_by_default {
      # tfsec:ignore:aws-s3-encryption-customer-key : KMS gerenciado pelo cliente custa $1/mês, SSE-S3 (gratuito) atende ao lab.
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id

  versioning_configuration {
    status = "Enabled"
  }
}