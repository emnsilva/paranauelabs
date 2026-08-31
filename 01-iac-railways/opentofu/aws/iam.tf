# iam.tf
# Provisionamento de Identidade e Acesso (IAM)
# Criação de Roles e Policies seguindo o Least Privilege (ADR-002)
# Nas duas regiões: Primária (sa-east-1) e Secundária (us-east-1)

# Bloco de dados local para definir o nome do bucket S3.
# Isso garante que a IAM Policy abaixo tenha o ARN exato do bucket sem precisar de CHAVES (hardcoded).
locals {
  s3_bucket_name_primary   = "paranauelabs-iac-railways-${var.environment}-primary"
  s3_bucket_name_secondary = "paranauelabs-iac-railways-${var.environment}-secondary"
}

# 1. IAM REGIÃO PRIMÁRIA (sa-east-1)

# Cria a IAM Role que a instância EC2 vai assumir.
# A "Assume Role Policy" diz: "Permito que o serviço EC2 da AWS assuma esta identidade temporariamente".
resource "aws_iam_role" "ec2_role_primary" {
  provider           = aws.primary
  name               = "ec2-role-${var.environment}-primary"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Cria o Instance Profile. É a "capa" que anexa a Role na instância EC2 durante a sua criação. 
# Sem ele, a EC2 não consegue usar a Role.
resource "aws_iam_instance_profile" "ec2_profile_primary" {
  provider = aws.primary
  name     = "ec2-profile-${var.environment}-primary"
  role     = aws_iam_role.ec2_role_primary.id
}

# Cria a Policy de permissões (Least Privilege).
# Em vez de dar permissão de "Admin" ou "S3:*" (que permitiria deletar buckets), permitimos APENAS ler (GetObject) e escrever 
# (PutObject) no bucket ESPECÍFICO deste laboratório.
resource "aws_iam_policy" "s3_access_policy_primary" {
  provider = aws.primary
  name     = "s3-access-policy-${var.environment}-primary"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.s3_bucket_name_primary}",
          "arn:aws:s3:::${local.s3_bucket_name_primary}/*"
        ]
      }
    ]
  })
}

# Anexa a Policy de S3 à Role da EC2.
resource "aws_iam_role_policy_attachment" "ec2_s3_attach_primary" {
  provider       = aws.primary
  role           = aws_iam_role.ec2_role_primary.id
  policy_arn     = aws_iam_policy.s3_access_policy_primary.arn
}

# 2. IAM REGIÃO SECUNDÁRIA (us-east-1)
# A mesma lógica, mas aplicada na região de Disaster Recovery (DR).

# Role para a EC2 Secundária
resource "aws_iam_role" "ec2_role_secondary" {
  provider           = aws.secondary
  name               = "ec2-role-${var.environment}-secondary"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })
}

# Instance Profile Secundário
resource "aws_iam_instance_profile" "ec2_profile_secondary" {
  provider = aws.secondary
  name     = "ec2-profile-${var.environment}-secondary"
  role     = aws_iam_role.ec2_role_secondary.id
}

# Policy de S3 (Least Privilege) Secundária
resource "aws_iam_policy" "s3_access_policy_secondary" {
  provider = aws.secondary
  name     = "s3-access-policy-${var.environment}-secondary"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = [
          "arn:aws:s3:::${local.s3_bucket_name_secondary}",
          "arn:aws:s3:::${local.s3_bucket_name_secondary}/*"
        ]
      }
    ]
  })
}

# Anexa a Policy à Role Secundária
resource "aws_iam_role_policy_attachment" "ec2_s3_attach_secondary" {
  provider       = aws.secondary
  role           = aws_iam_role.ec2_role_secondary.id
  policy_arn     = aws_iam_policy.s3_access_policy_secondary.arn
}