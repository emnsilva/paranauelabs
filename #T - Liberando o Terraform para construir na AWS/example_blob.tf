variable "ARM_PRIMARY_REGION" {}
variable "ARM_SECONDARY_REGION" {}

# Configurações principais usando variáveis do Terraform Cloud
resource "azurerm_resource_group" "primary" {
  name     = "primary-blob-storage-${lower(var.ARM_PRIMARY_REGION)}"
  location = var.ARM_PRIMARY_REGION
}

resource "azurerm_resource_group" "secondary" {
  name     = "secondary-blob-storage-${lower(var.ARM_SECONDARY_REGION)}"
  location = var.ARM_SECONDARY_REGION
}

resource "azurerm_storage_account" "primary" {
  name                     = "paranaueblob${replace(lower(var.ARM_PRIMARY_REGION), "[^a-z0-9]", "")}"
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "secondary" {
  name                     = "paranaueblob${replace(lower(var.ARM_SECONDARY_REGION), "[^a-z0-9]", "")}"
  resource_group_name      = azurerm_resource_group.secondary.name
  location                 = azurerm_resource_group.secondary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "primary" {
  name                  = "primary-container-${lower(var.ARM_PRIMARY_REGION)}"
  storage_account_id    = azurerm_storage_account.primary.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "secondary" {
  name                  = "secondary-container-${lower(var.ARM_SECONDARY_REGION)}"
  storage_account_id    = azurerm_storage_account.secondary.id
  container_access_type = "private"
}
