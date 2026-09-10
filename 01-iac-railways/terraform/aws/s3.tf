# s3.tf
# Provisionamento de Armazenamento (Buckets S3)
# Nas duas regiões: Primária (sa-east-1) e Secundária (us-east-1)

# 1. Região Primária (sa-east-1)
# tfsec:ignore:aws-s3-enable-bucket-logging : Logging exige criação de um segundo bucket de logs, fora do escopo do laboratório.
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = local.s3_bucket_name_primary

  tags = {
    Name = local.s3_bucket_name_primary
  }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  provider                = aws.primary
  bucket                  = aws_s3_bucket.primary.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# tfsec:ignore:aws-s3-encryption-customer-key : KMS gerenciado pelo cliente custa $1/mês, SSE-S3 (gratuito) atende ao lab.
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Região Secundária (us-east-1)
# tfsec:ignore:aws-s3-enable-bucket-logging : Logging exige criação de um segundo bucket de logs, fora do escopo do laboratório.
resource "aws_s3_bucket" "secondary" {
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

# tfsec:ignore:aws-s3-encryption-customer-key : KMS gerenciado pelo cliente custa $1/mês, SSE-S3 (gratuito) atende ao lab.
resource "aws_s3_bucket_server_side_encryption_configuration" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id

  rule {
    apply_server_side_encryption_by_default {
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