# Outputs do módulo S3 Bucket com replicação entre regiões
# Informações úteis para consumo por outros módulos ou usuários

output "rg_primario" {
  description = "Informações do resource group primário"
  value = {
    nome     = azurerm_resource_group.primary.name
    location = azurerm_resource_group.primary.location
  }
}

output "rg_secundario" {
  description = "Informações do resource group secundário"
  value = {
    nome     = azurerm_resource_group.secondary.name
    location = azurerm_resource_group.secondary.location
  }
}

output "storage_primaria" {
  description = "Informações da storage account primária"
  value = {
    nome          = azurerm_storage_account.primary.name
    resource_group = azurerm_resource_group.primary.name
    location      = azurerm_storage_account.primary.location
    tipo_conta    = azurerm_storage_account.primary.account_tier
    replicacao    = azurerm_storage_account.primary.account_replication_type
  }
}

output "storage_secundaria" {
  description = "Informações da storage account secundária"
  value = {
    nome          = azurerm_storage_account.secondary.name
    resource_group = azurerm_resource_group.secondary.name
    location      = azurerm_storage_account.secondary.location
    tipo_conta    = azurerm_storage_account.secondary.account_tier
    replicacao    = azurerm_storage_account.secondary.account_replication_type
  }
}

output "containers_criados" {
  description = "Containers criados em cada storage account"
  value = {
    primaria = [for c in azurerm_storage_container.primary_containers : c.name]
    secundaria = [for c in azurerm_storage_container.secondary_containers : c.name]
  }
}

output "configuracoes_aplicadas" {
  description = "Resumo das configurações aplicadas"
  value = {
    tipo_conta        = var.tipo_conta
    tipo_replicacao   = var.tipo_replicacao
    tipo_acesso       = var.tipo_acesso_container
    total_containers  = length(var.nomes_containers)
    ambiente          = var.ambiente
  }
}