variable "ARM_PRIMARY_REGION" {}
variable "ARM_SECONDARY_REGION" {}

# Recursos primários
resource "azurerm_resource_group" "primary" {
  provider = azurerm.primary
  name     = "primary-blob-storage"
  location = var.ARM_PRIMARY_REGION
}

resource "azurerm_storage_account" "primary" {
  provider                 = azurerm.primary
  name                     = "primarystorage"
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Recursos secundários
resource "azurerm_resource_group" "secondary" {
  provider = azurerm.secondary
  name     = "secondary-blob-storage"
  location = var.ARM_SECONDARY_REGION
}

resource "azurerm_storage_account" "secondary" {
  provider                 = azurerm.secondary
  name                     = "secondarystorage"
  resource_group_name      = azurerm_resource_group.secondary.name
  location                 = azurerm_resource_group.secondary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Containers
resource "azurerm_storage_container" "primary" {
  provider           = azurerm.primary
  name               = "primary-container"
  storage_account_id = azurerm_storage_account.primary.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "secondary" {
  provider           = azurerm.secondary
  name               = "secondary-container"
  storage_account_id = azurerm_storage_account.secondary.id
  container_access_type = "private"
}
