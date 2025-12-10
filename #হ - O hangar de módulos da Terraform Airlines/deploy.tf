# Este arquivo orquestra a implantação de storage em três provedores de nuvem, com módulos reutilizáveis.

# Módulo AWS: Buckets S3 com configurações padrão
module "aws_s3" {
  source = "./modules/s3_buckets"

  # Configuração de provedores por região
  providers = {
    aws.primary   = aws.primary       # Região primária
    aws.secondary = aws.secondary     # Região secundária  
  }

  # Parâmetros do módulo
  prefixo_projeto   = var.PREFIXO_PROJETO
  ambiente          = var.ENVIRONMENT
  primary_region    = var.AWS_REGION_PRIMARY
  secondary_region  = var.AWS_REGION_SECONDARY
  tags_globais      = var.TAGS_GLOBAIS

  # Configurações de segurança e compliance
  habilitar_versionamento = true
  permitir_destruicao_rapida = var.ENVIRONMENT == "dev" ? true : false

  # Lifecycle policies
  regras_lifecycle = var.ENVIRONMENT == "prod" ? {
    logs = {
      dias_expiracao = 90
      prefixo        = "logs/"
    }
    temp = {
      dias_expiracao = 7
      prefixo        = "temp/"
    }
  } : {}
}

# Módulo AZURE: Storage accounts e containers
module "azure_blob_storage" {
  source = "./modules/blob_storage"

  # Configuração de provedores por região
  providers = {
    azurerm.primary   = azurerm.primary    # Região primária
    azurerm.secondary = azurerm.secondary  # Região secundária
  }

  # Parâmetros do módulo
  prefixo             = substr(var.PREFIXO_PROJETO, 0, 10)
  ambiente            = var.ENVIRONMENT
  primary_region      = var.ARM_PRIMARY_REGION
  secondary_region    = var.ARM_SECONDARY_REGION
  tags_globais        = var.TAGS_GLOBAIS

  # Configurações técnicas
  tipo_conta              = var.ENVIRONMENT == "prod" ? "Premium" : "Standard"
  tipo_replicacao         = var.ENVIRONMENT == "prod" ? "GRS" : "LRS"
  tipo_acesso_container   = var.ENVIRONMENT == "dev" ? "container" : "private"
  habilitar_versionamento = true
  habilitar_soft_delete   = true
  dias_retencao_delete    = var.ENVIRONMENT == "prod" ? 90 : 30
  nomes_containers        = ["dados", "logs", "backup"]
}

# Módulo GCP: Cloud storage buckets
module "armazenamento_gcp" {
  source = "./modules/gcs_storage"

  # Configuração de provedores por região
  providers = {
    google.primary   = google.primary
    google.secondary = google.secondary
  }

  # Parâmetros obrigatórios
  project_id       = var.GCP_PROJECT
  ambiente         = var.ENVIRONMENT
  primary_region   = var.GCP_PRIMARY_REGION
  secondary_region = var.GCP_SECONDARY_REGION
  tags_globais     = var.TAGS_GLOBAIS

  # Configurações de storage
  classe_armazenamento    = "STANDARD"
  habilitar_versionamento = true
  acesso_uniforme         = true

  # Regras de lifecycle (exemplo)
  regras_lifecycle = {
    autoArchive = {
      acao_tipo              = "SetStorageClass"
      acao_classe            = "ARCHIVE"
      condicao_idade         = 365
      condicao_estado        = "ANY"
      condicao_classe        = ["STANDARD", "NEARLINE"]
      condicao_versoes_novas = null
    }
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