# main.tf - Implementação do Bucket S3 com provider dinâmico

resource "aws_s3_bucket" "this" {
  provider      = var.provider_alias == "primary" ? aws.primary : aws.secondary
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "this" {
  provider = var.provider_alias == "primary" ? aws.primary : aws.secondary

  bucket = aws_s3_bucket.this.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}