# Cria buckets Cloud Storage em regiões primária e secundária

# Storage GCP primário
resource "google_storage_bucket" "primary" {
  name          = "${var.project_id}-${var.ambiente}-primary"
  location      = var.primary_region
  storage_class = var.classe_armazenamento
  force_destroy = var.ambiente == "dev" ? true : false
  
  # Labels convertidas das tags globais
  labels = local.labels_gcp
  
  # Versionamento
  versioning {
    enabled = var.habilitar_versionamento
  }
  
  # Segurança
  uniform_bucket_level_access = var.acesso_uniforme
  
  # Lifecycle rules dinâmicas
  dynamic "lifecycle_rule" {
    for_each = var.regras_lifecycle
    
    content {
      action {
        type          = lifecycle_rule.value.acao_tipo
        storage_class = lifecycle_rule.value.acao_classe
      }
      
      condition {
        age                   = lifecycle_rule.value.condicao_idade
        with_state            = lifecycle_rule.value.condicao_estado
        matches_storage_class = lifecycle_rule.value.condicao_classe
        num_newer_versions    = lifecycle_rule.value.condicao_versoes_novas
      }
    }
  }
}

# Storage GCP secundário
resource "google_storage_bucket" "secondary" {
  provider = google.secondary
  name          = "${var.project_id}-${var.ambiente}-secondary"
  location      = var.secondary_region
  storage_class = var.classe_armazenamento
  force_destroy = var.ambiente == "dev" ? true : false
  
  # Labels convertidas das tags globais
  labels = local.labels_gcp
  
  # Versionamento
  versioning {
    enabled = var.habilitar_versionamento
  }
  
  # Segurança
  uniform_bucket_level_access = var.acesso_uniforme
  
  # Lifecycle rules dinâmicas
  dynamic "lifecycle_rule" {
    for_each = var.regras_lifecycle
    
    content {
      action {
        type          = lifecycle_rule.value.acao_tipo
        storage_class = lifecycle_rule.value.acao_classe
      }
      
      condition {
        age                   = lifecycle_rule.value.condicao_idade
        with_state            = lifecycle_rule.value.condicao_estado
        matches_storage_class = lifecycle_rule.value.condicao_classe
        num_newer_versions    = lifecycle_rule.value.condicao_versoes_novas
      }
    }
  }
}

# Locals para conversão de tags para labels
locals {
  labels_gcp = {
    for key, value in var.tags_globais :
    # Converte hífen para underscore (formato GCP)
    replace(key, "-", "_") => replace(value, "-", "_")
  }
}
