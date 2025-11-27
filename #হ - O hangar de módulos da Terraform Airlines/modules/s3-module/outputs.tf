# outputs.tf - Relatórios de voo do módulo S3

output "primary_bucket_arn" {
  description = "ARN do bucket S3 na região primary"
  value       = try(aws_s3_bucket.primary.arn, null)
}

output "primary_bucket_id" {
  description = "ID do bucket S3 na região primary"  
  value       = try(aws_s3_bucket.primary.id, null)
}

output "primary_bucket_region" {
  description = "Região do bucket S3 primary"
  value       = try(aws_s3_bucket.primary.region, null)
}

output "secondary_bucket_arn" {
  description = "ARN do bucket S3 na região secondary"
  value       = try(aws_s3_bucket.secondary.arn, null)
}

output "secondary_bucket_id" {
  description = "ID do bucket S3 na região secondary"
  value       = try(aws_s3_bucket.secondary.id, null)
}

output "secondary_bucket_region" {
  description = "Região do bucket S3 secondary"  
  value       = try(aws_s3_bucket.secondary.region, null)
}

output "all_buckets" {
  description = "Mapa com todos os buckets criados"
  value = {
    primary = {
      arn    = try(aws_s3_bucket.primary.arn, null)
      id     = try(aws_s3_bucket.primary.id, null)
      region = try(aws_s3_bucket.primary.region, null)
    }
    secondary = {
      arn    = try(aws_s3_bucket.secondary.arn, null)
      id     = try(aws_s3_bucket.secondary.id, null) 
      region = try(aws_s3_bucket.secondary.region, null)
    }
  }
}