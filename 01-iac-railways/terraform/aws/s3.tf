# s3.tf
# Provisionamento de Armazenamento (Buckets S3) nas duas regiões: Primária (sa-east-1) e Secundária (us-east-1)

# 1. STORAGE REGIÃO PRIMÁRIA (sa-east-1)
# Cria o Bucket S3 na região primária.
# O nome usa o bloco 'locals' definido no iam.tf para garantir que seja globalmente único e bata 100% com a IAM Policy.
resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = local.s3_bucket_name_primary

  tags = {
    Name = local.s3_bucket_name_primary
  }
}

# Configuração de Segurança: Bloqueia TODO o acesso público ao bucket.
# É a configuração padrão para qualquer bucket que contenha dados 
# privados ou de infraestrutura.
resource "aws_s3_bucket_public_access_block" "primary" {
  provider                = aws.primary
  bucket                  = aws_s3_bucket.primary.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Configuração de Segurança: Ativa a criptografia em repouso (SSE-S3).
# Garante que se alguém conseguir baixar um arquivo do bucket, o arquivo 
# estará inutilizável sem a chave da AWS.
resource "aws_s3_bucket_server_side_encryption_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

# Governança: Ativa o versionamento do bucket.
# Protege contra deleções acidentais, mantendo um histórico de 
# versões de cada arquivo enviado.
resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

# 2. STORAGE REGIÃO SECUNDÁRIA (us-east-1)
# A mesma lógica de segurança, mas na região de DR.

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