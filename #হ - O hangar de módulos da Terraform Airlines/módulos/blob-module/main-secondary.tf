# Resource Group secondary
resource "azurerm_resource_group" "secondary" {
  provider = azurerm.secondary
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

# Storage Account secondary
resource "azurerm_storage_account" "secondary" {
  provider                 = azurerm.secondary
  name                     = var.storage_account_name
  resource_group_name      = azurerm_resource_group.secondary.name
  location                 = azurerm_resource_group.secondary.location
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

# Container secondary
resource "azurerm_storage_container" "secondary" {
  provider               = azurerm.secondary
  name                   = var.container_name
  storage_account_id     = azurerm_storage_account.secondary.id
  container_access_type  = var.container_access_type
}