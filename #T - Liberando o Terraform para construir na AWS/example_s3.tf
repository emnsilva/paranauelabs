# Provedor para região primária
provider "aws" {
  alias  = "primary"
  region = locals.region_mapping[var.CLOUD_PRIMARY_REGION].aws
}

# Provedor para região secundária
provider "aws" {
  alias  = "secondary"
  region = locals.region_mapping[var.CLOUD_SECONDARY_REGION].aws
}

# Bucket na região primária
resource "aws_s3_bucket" "bucket_primary" {
  provider      = aws.primary
  bucket        = "main-bucket"  # Nome único globalmente
  force_destroy = true
}

# Bucket na região secundária
resource "aws_s3_bucket" "bucket_secondary" {
  provider      = aws.secondary
  bucket        = "backup-bucket"  # Nome único globalmente
  force_destroy = true
}
