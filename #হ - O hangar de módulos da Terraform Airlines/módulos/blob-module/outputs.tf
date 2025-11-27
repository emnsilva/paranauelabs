output "primary_storage_account_id" {
  description = "ID da storage account primary"
  value       = try(azurerm_storage_account.primary.id, null)
}

output "primary_container_id" {
  description = "ID do container primary"
  value       = try(azurerm_storage_container.primary.id, null)
}

output "primary_resource_group_name" {
  description = "Nome do resource group primary"
  value       = try(azurerm_resource_group.primary.name, null)
}

output "secondary_storage_account_id" {
  description = "ID da storage account secondary"
  value       = try(azurerm_storage_account.secondary.id, null)
}

output "secondary_container_id" {
  description = "ID do container secondary"
  value       = try(azurerm_storage_container.secondary.id, null)
}

output "secondary_resource_group_name" {
  description = "Nome do resource group secondary"
  value       = try(azurerm_resource_group.secondary.name, null)
}

output "all_resources" {
  description = "Mapa com todos os recursos Azure"
  value = {
    primary = {
      storage_account_id = try(azurerm_storage_account.primary.id, null)
      container_id       = try(azurerm_storage_container.primary.id, null)
      resource_group     = try(azurerm_resource_group.primary.name, null)
    }
    secondary = {
      storage_account_id = try(azurerm_storage_account.secondary.id, null)
      container_id       = try(azurerm_storage_container.secondary.id, null)
      resource_group     = try(azurerm_resource_group.secondary.name, null)
    }
  }
}