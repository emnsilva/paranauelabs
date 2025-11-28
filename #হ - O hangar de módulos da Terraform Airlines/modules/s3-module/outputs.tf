# outputs.tf - Relatórios de voo do módulo S3

output "bucket_arn" {
  description = "ARN do bucket S3 criado"
  value       = aws_s3_bucket.bucket.arn
}

output "bucket_id" {
  description = "ID (nome) do bucket S3 criado"
  value       = aws_s3_bucket.bucket.id
}

output "bucket_region" {
  description = "Região AWS do bucket S3"
  value       = aws_s3_bucket.bucket.region
}