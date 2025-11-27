variable "AWS_REGION_PRIMARY" {}

resource "aws_s3_bucket" "primary" {
  provider      = aws.primary
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
  region        = var.region
}

resource "aws_s3_bucket_public_access_block" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
