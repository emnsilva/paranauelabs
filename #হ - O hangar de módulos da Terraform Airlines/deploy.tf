# Este arquivo orquestra a implantação de storage em três provedores de nuvem, com módulos reutilizáveis.

# Módulo AWS: Buckets S3 com configurações padrão
module "aws_s3" {
  source = "./modules/s3_buckets"

  # Configuração de provedores por região
  providers = {
    aws.primary   = aws.primary       # Região primária
    aws.secondary = aws.secondary     # Região secundária  
  }
}

# Módulo AZURE: Storage accounts e containers
module "azure_blob_storage" {
  source = "./modules/blob_storage"

  # Configuração de provedores por região
   providers = {
    azurerm.primary   = azurerm.primary
    azurerm.secondary = azurerm.secondary
  }
}

# Módulo GCP: Cloud storage buckets
module "armazenamento_gcp" {
  source = "./modules/gcs_storage"

  # Configuração de provedores por região
  providers = {
    google.primary   = google.primary
    google.secondary = google.secondary
  }
}

# Outputs consolidados
output "dashboard_armazenamento_multi_cloud" {
  description = "Painel consolidado de todos os recursos de storage"
  value = {
    aws = {
      buckets = {
        primario   = module.armazenamento_aws.bucket_primario.nome
        secundario = module.armazenamento_aws.bucket_secundario.nome
      }
      urls = module.armazenamento_aws.urls_acesso
    }
    azure = {
      storage_accounts = {
        primaria   = module.armazenamento_azure.conta_primaria.nome
        secundaria = module.armazenamento_azure.conta_secundaria.nome
      }
      resource_groups = {
        primario   = module.armazenamento_azure.rg_primario.nome
        secundario = module.armazenamento_azure.rg_secundario.nome
      }
    }
    gcp = {
      buckets = {
        primario   = module.armazenamento_gcp.bucket_primario.nome
        secundario = module.armazenamento_gcp.bucket_secundario.nome
      }
      projeto = var.GCP_PROJECT
    }
  }
}

output "urls_acesso_rapido" {
  description = "URLs de acesso direto aos principais recursos"
  value = {
    aws_primary    = module.armazenamento_aws.urls_acesso.primario
    aws_secondary  = module.armazenamento_aws.urls_acesso.secundario
    gcp_primary    = "https://console.cloud.google.com/storage/browser/${module.armazenamento_gcp.bucket_primario.nome}"
    gcp_secondary  = "https://console.cloud.google.com/storage/browser/${module.armazenamento_gcp.bucket_secundario.nome}"
    azure_primary  = "https://portal.azure.com/#@/resource${module.armazenamento_azure.conta_primaria.id}/overview"
  }
  sensitive = false
}

output "resumo_implantação" {
  description = "Resumo da implantação multi-cloud"
  value = <<EOT
✅ IMPLANTAÇÃO MULTI-CLOUD CONCLUÍDA

Projeto: Terraform Airlines
Ambiente: ${var.ENVIRONMENT}

Recursos criados:
- AWS:   2 buckets S3 (${var.AWS_REGION_PRIMARY}, ${var.AWS_REGION_SECONDARY})
- Azure: 2 storage accounts + containers (${var.ARM_PRIMARY_REGION}, ${var.ARM_SECONDARY_REGION})
- GCP:   2 Cloud Storage buckets (${var.GCP_PRIMARY_REGION}, ${var.GCP_SECONDARY_REGION})

Configurações aplicadas:
• Versionamento habilitado em todos os provedores
• Tags/Labels padronizadas
• Políticas de segurança configuradas
• Lifecycle rules conforme ambiente

Próximos passos:
1. Verificar acesso aos recursos
2. Configurar monitoring
3. Documentar procedimentos operacionais
EOT
}
