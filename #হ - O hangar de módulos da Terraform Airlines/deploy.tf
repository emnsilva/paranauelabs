# Este arquivo orquestra a implantação de storage em três provedores de nuvem, com módulos reutilizáveis.

# Módulo AWS: Buckets S3 com configurações padrão
module "aws_s3" {
  source = "./s3_buckets"

  providers = {
    aws           = aws.primary
    aws.secondary = aws.secondary
  }

  PREFIXO_PROJETO        = var.PREFIXO_PROJETO
  ENVIRONMENT            = var.ENVIRONMENT
  TAGS_GLOBAIS           = var.TAGS_GLOBAIS
  habilitar_versionamento = true
  regras_lifecycle = {
    logs = { dias_expiracao = 90, prefixo = "logs/" }
    temp = { dias_expiracao = 7,  prefixo = "temp/" }
  }
}

# Módulo AZURE: Storage accounts e containers
module "azure_blob_storage" {
  source = "./blob_storage"

  providers = {
    azurerm           = azurerm.primary
    azurerm.secondary = azurerm.secondary
  }

  prefixo            = var.PREFIXO_PROJETO
  ambiente           = var.ENVIRONMENT
  primary_region     = var.ARM_PRIMARY_REGION
  secondary_region   = var.ARM_SECONDARY_REGION
  tags_globais       = var.TAGS_GLOBAIS
  nomes_containers   = ["app", "logs"]
  tipo_conta         = "Standard"
  tipo_replicacao    = "LRS"
  tipo_acesso_container = "private"
}

# Módulo GCP: Cloud storage buckets
module "gcp_storage" {
  source = "./gcs_storage"

  providers = {
    google           = google.primary
    google.secondary = google.secondary
  }

  project_id             = var.GCP_PROJECT
  ambiente               = var.ENVIRONMENT
  primary_region         = var.GCP_PRIMARY_REGION
  secondary_region       = var.GCP_SECONDARY_REGION
  tags_globais           = var.TAGS_GLOBAIS
  classe_armazenamento   = "STANDARD"
  habilitar_versionamento = true
  acesso_uniforme        = true
  regras_lifecycle       = {}
  }

# Outputs consolidados
output "dashboard_armazenamento_multi_cloud" {
  description = "Painel consolidado de todos os recursos de storage"
  value = {
    aws = {
      buckets = {
        primario   = module.aws_s3.bucket_primario.nome
        secundario = module.aws_s3.bucket_secundario.nome
      }
      urls = module.aws_s3.urls_acesso
    }
    azure = {
      storage_accounts = {
        primaria   = module.azure_blob_storage.storage_primaria.nome
        secundaria = module.azure_blob_storage.storage_secundaria.nome
      }
      resource_groups = {
        primario   = module.azure_blob_storage.rg_primario.nome
        secundario = module.azure_blob_storage.rg_secundario.nome
      }
    }
    gcp = {
      buckets = {
        primario   = module.gcp_storage.bucket_primario.nome
        secundario = module.gcp_storage.bucket_secundario.nome
      }
      projeto = var.GCP_PROJECT
    }
  }
}

output "urls_acesso_rapido" {
  description = "URLs de acesso direto aos principais recursos"
  value = {
    aws_primary    = module.aws_s3.urls_acesso.primario
    aws_secondary  = module.aws_s3.urls_acesso.secundario
    gcp_primary    = "https://console.cloud.google.com/storage/browser/${module.gcp_storage.bucket_primario.nome}"
    gcp_secondary  = "https://console.cloud.google.com/storage/browser/${module.gcp_storage.bucket_secundario.nome}"
    azure_primary  = "https://portal.azure.com/#@/resource${module.azure_blob_storage.storage_primaria.nome}/overview"
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