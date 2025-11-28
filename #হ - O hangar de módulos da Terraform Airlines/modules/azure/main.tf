# Módulo Azure - Storage Accounts e Containers em duas regiões

variable "primary_region" {
  description = "Região primária do Azure"
  type        = string
}

variable "secondary_region" {
  description = "Região secundária do Azure"
  type        = string
}

resource "azurerm_resource_group" "primary" {
  name     = "terraform-airlines-primary-rg"
  location = var.primary_region
}

resource "azurerm_resource_group" "secondary" {
  name     = "terraform-airlines-secondary-rg"
  location = var.secondary_region
}

resource "azurerm_storage_account" "primary" {
  name                     = "tairstorageprimary"
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "secondary" {
  name                     = "tairstoragesecondary"
  resource_group_name      = azurerm_resource_group.secondary.name
  location                 = azurerm_resource_group.secondary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "primary" {
  name                  = "primary-container"
  storage_account_id    = azurerm_storage_account.primary.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "secondary" {
  name                  = "secondary-container"
  storage_account_id    = azurerm_storage_account.secondary.id
  container_access_type = "private"
}

output "primary_storage_account_name" {
  description = "Nome da conta de armazenamento primária"
  value       = azurerm_storage_account.primary.name
}

output "secondary_storage_account_name" {
  description = "Nome da conta de armazenamento secundária"
  value       = azurerm_storage_account.secondary.name
}
