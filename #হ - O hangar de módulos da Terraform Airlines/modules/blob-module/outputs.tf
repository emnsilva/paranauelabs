output "resource_group_name" {
  description = "Nome do Resource Group criado."
  value       = azurerm_resource_group.rg.name
}

output "storage_account_id" {
  description = "ID da Storage Account criada."
  value       = azurerm_storage_account.sa.id
}

output "storage_account_name" {
  description = "Nome da Storage Account criada."
  value       = azurerm_storage_account.sa.name
}

output "container_id" {
  description = "ID do Storage Container criado."
  value       = azurerm_storage_container.container.id
}