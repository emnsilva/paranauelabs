# Outputs do módulo GCP storage com replicação entre regiões
# Informações úteis para consumo por outros módulos ou usuários

output "bucket_primario" {
  description = "Informações do bucket Cloud Storage primário"
  value = {
    nome     = google_storage_bucket.primary.name
    url      = google_storage_bucket.primary.url
    location = google_storage_bucket.primary.location
  }
}

output "bucket_secundario" {
  description = "Informações do bucket Cloud Storage secundário"
  value = {
    nome     = google_storage_bucket.secondary.name
    url      = google_storage_bucket.secondary.url
    location = google_storage_bucket.secondary.location
  }
}

output "labels_aplicadas" {
  description = "Labels aplicadas aos buckets GCP"
  value = local.labels_gcp
}

output "configuracoes_aplicadas" {
  description = "Resumo das configurações aplicadas"
  value = {
    storage_class    = var.classe_armazenamento
    versionamento    = var.habilitar_versionamento ? "habilitado" : "desabilitado"
    acesso_uniforme  = var.acesso_uniforme
    total_regras_lifecycle = length(var.regras_lifecycle)
    ambiente         = var.ambiente
  }
}