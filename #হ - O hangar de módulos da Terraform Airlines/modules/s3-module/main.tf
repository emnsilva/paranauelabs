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

# Adiciona uma configuração vazia para o provedor aws.
# Isso informa ao Terraform que a configuração deste provedor será passada pelo módulo raiz (root module).
provider "aws" {}

resource "aws_s3_bucket" "bucket" {
  provider      = aws
  bucket        = var.bucket_name
  force_destroy = var.force_destroy
  tags          = var.tags
}