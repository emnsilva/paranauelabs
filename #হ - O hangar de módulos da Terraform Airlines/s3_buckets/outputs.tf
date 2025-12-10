# Outputs do módulo S3 Bucket com replicação entre regiões
# Informações úteis para consumo por outros módulos ou usuários

output "bucket_primario" {
  description = "Informações completas do bucket S3 primário"
  value = {
    nome = aws_s3_bucket.primary.id
    arn  = aws_s3_bucket.primary.arn
    regiao = "primary"
  }
}

output "bucket_secundario" {
  description = "Informações completas do bucket S3 secundário"
  value = {
    nome = aws_s3_bucket.secondary.id
    arn  = aws_s3_bucket.secondary.arn
    regiao = "secondary"
  }
}

output "urls_acesso" {
  description = "URLs de acesso público aos buckets"
  value = {
    primario   = "https://${aws_s3_bucket.primary.id}.s3.amazonaws.com"
    secundario = "https://${aws_s3_bucket.secondary.id}.s3.amazonaws.com"
  }
}

output "configuracoes_aplicadas" {
  description = "Resumo das configurações aplicadas nos buckets"
  value = {
    versionamento  = var.habilitar_versionamento ? "habilitado" : "desabilitado"
    criptografia   = "AES256"
    total_regras_lifecycle = length(var.regras_lifecycle)
    ambiente       = var.ENVIRONMENT
  }
}