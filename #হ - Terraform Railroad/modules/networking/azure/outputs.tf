# Exporta os dados da VNet e do Resource Group.

output "vnet_id" {
  description = "O ID da Virtual Network (Malha)"
  value       = azurerm_virtual_network.this.id
}

output "subnet_ids" {
  description = "Lista de IDs das subnets (Trilhos)"
  value       = concat(azurerm_subnet.standard[*].id, azurerm_subnet.hq_extra[*].id)
}

output "resource_group_name" {
  description = "Nome do Resource Group (Terreno)"
  value       = azurerm_resource_group.this.name
}