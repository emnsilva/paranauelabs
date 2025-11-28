resource "aws_s3_bucket" "secondary" {
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}

resource "aws_s3_bucket_public_access_block" "secondary" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.secondary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
