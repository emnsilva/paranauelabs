# main.tf - Lógica de criação do bucket S3

# Cada provedor precisa ser configurado no módulo raiz e passado explicitamente.
# O Terraform não herda provedores com alias automaticamente para dentro de módulos.
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.9.0"
    }
  }
}

resource "aws_s3_bucket" "bucket" {
  provider      = aws
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}