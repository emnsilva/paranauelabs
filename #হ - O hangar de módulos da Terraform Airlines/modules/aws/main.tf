# Módulo AWS - Buckets S3 em duas regiões

variable "primary_region" {
  description = "Região primária da AWS"
  type        = string
}

variable "secondary_region" {
  description = "Região secundária da AWS"
  type        = string
}

resource "aws_s3_bucket" "primary" {
  bucket        = "terraform-airlines-primary-bucket"
  force_destroy = true
}

resource "aws_s3_bucket" "secondary" {
  bucket        = "terraform-airlines-secondary-bucket"
  force_destroy = true
}

output "primary_bucket_name" {
  description = "Nome do bucket S3 primário"
  value       = aws_s3_bucket.primary.id
}

output "secondary_bucket_name" {
  description = "Nome do bucket S3 secundário"
  value       = aws_s3_bucket.secondary.id
}
