# Resource Group primary
resource "azurerm_resource_group" "primary" {
  provider = azurerm.primary
  name     = var.resource_group_name
  location = var.location

  tags = merge(
    var.tags,
    {
      Module    = "blob-storage"
      CreatedBy = "terraform-airlines"
    }
  )
}

# Storage Account primary
resource "azurerm_storage_account" "primary" {
  provider                 = azurerm.primary
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = var.account_tier
  account_replication_type = var.replication_type

  tags = merge(
    var.tags,
    {
      Module    = "blob-storage"
      CreatedBy = "terraform-airlines"
    }
  )
}

# Container primary
resource "azurerm_storage_container" "primary" {
  provider             = azurerm.primary
  name                 = var.container_name
  storage_account_id   = azurerm_storage_account.primary.id
  container_access_type = var.container_access_type
}