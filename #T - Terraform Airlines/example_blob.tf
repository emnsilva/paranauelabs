variable "ARM_PRIMARY_REGION" {}
variable "ARM_SECONDARY_REGION" {}
variable "TFC_AZURE_PROVIDER_AUTH" {
  type    = bool
  default = null
}

provider "azurerm" {
  features {}
  use_oidc = var.TFC_AZURE_PROVIDER_AUTH != null ? var.TFC_AZURE_PROVIDER_AUTH : false
}

provider "azurerm" {
  alias  = "primary"
  features {}
  use_oidc = var.TFC_AZURE_PROVIDER_AUTH != null ? var.TFC_AZURE_PROVIDER_AUTH : false
}

provider "azurerm" {
  alias  = "secondary"
  features {}
  use_oidc = var.TFC_AZURE_PROVIDER_AUTH != null ? var.TFC_AZURE_PROVIDER_AUTH : false
}

# Configurações principais usando variáveis do Terraform Cloud
resource "azurerm_resource_group" "primary" {
  name     = "primary-blob-storage"
  provider = azurerm.primary
  location = var.ARM_PRIMARY_REGION
}

# Configurações principais usando variáveis do Terraform Cloud
resource "azurerm_resource_group" "secondary" {
  name     = "secondary-blob-storage"
  provider = azurerm.secondary
  location = var.ARM_SECONDARY_REGION
}

resource "azurerm_storage_account" "primary" {
  name                     = "primarystorage"
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_account" "secondary" {
  name                     = "secondarystorage"
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
