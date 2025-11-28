# main.tf - Lógica de criação dos recursos do Azure Blob Storage

terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.40.0"
    }
  }
}

# Cria um Resource Group para organizar os recursos
resource "azurerm_resource_group" "rg" {
  provider = azurerm
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Cria a Storage Account dentro do Resource Group
resource "azurerm_storage_account" "sa" {
  provider                 = azurerm
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type
  tags                     = var.tags
}

# Cria o Container dentro da Storage Account
resource "azurerm_storage_container" "container" {
  provider              = azurerm
  name                  = var.container_name
  storage_account_name  = azurerm_storage_account.sa.name
  container_access_type = var.container_access_type
}