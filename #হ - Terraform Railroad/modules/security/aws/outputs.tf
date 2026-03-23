output "security_group_id" {
  description = "ID do Security Group (Cancela)"
  value       = aws_security_group.this.id
}

output "iam_role_arn" {
  description = "ARN da Role IAM (Chave)"
  value       = aws_iam_role.this.arn
}