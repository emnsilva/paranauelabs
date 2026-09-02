# blob.tf
# Provisionamento de Armazenamento (Storage Accounts)

# Storage Account Primária (Nomes devem ser globalmente únicos e minúsculos)
resource "azurerm_storage_account" "storage_primary" {
  name                     = "stpnauelabs${var.environment}p"
  resource_group_name      = azurerm_resource_group.rg_primary.name
  location                 = azurerm_resource_group.rg_primary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}

# Storage Account Secundária (DR)
resource "azurerm_storage_account" "storage_secondary" {
  name                     = "stpnauelabs${var.environment}s"
  resource_group_name      = azurerm_resource_group.rg_secondary.name
  location                 = azurerm_resource_group.rg_secondary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  min_tls_version          = "TLS1_2"
}