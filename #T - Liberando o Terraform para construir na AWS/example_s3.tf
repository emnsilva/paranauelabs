# Provedor para região primária
provider "aws" {
  alias  = "primary"
  region = local.region_mapping[var.PRIMARY_REGION_ALIAS].aws
}

# Provedor para região secundária
provider "aws" {
  alias  = "secondary"
  region = local.region_mapping[var.SECONDARY_REGION_ALIAS].aws
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
