# Configuração dos providers para cada região
provider "azurerm" {
  features {}
  alias           = "brazilsouth"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  skip_provider_registration = true
}

provider "azurerm" {
  features {}
  alias           = "eastus"
  subscription_id = var.subscription_id
  client_id       = var.client_id
  client_secret   = var.client_secret
  tenant_id       = var.tenant_id
  skip_provider_registration = true
}

# Grupo de recursos na região primária (Brazil South)
resource "azurerm_resource_group" "primary" {
  provider = azurerm.brazilsouth
  name     = "paranaublob-primary-rg"
  location = "brazilsouth"
}

# Grupo de recursos na região secundária (East US)
resource "azurerm_resource_group" "secondary" {
  provider = azurerm.eastus
  name     = "paranaublob-secondary-rg"
  location = "eastus"
}

# Conta de armazenamento PRIMÁRIA (Brazil South)
resource "azurerm_storage_account" "primary" {
  provider                 = azurerm.brazilsouth
  name                     = "paranaublobprimary"  # Nome deve ser único globalmente
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = "Standard"
  account_replication_type = "GRS"  # Replicação geográfica para failover

  # Habilita redundância entre regiões
  geo_redundant_location {
    location = "eastus"
    zone_redundant = false
  }
}

# Conta de armazenamento SECUNDÁRIA (East US - opcional para acesso ativo)
resource "azurerm_storage_account" "secondary" {
  provider                 = azurerm.eastus
  name                     = "paranaublobsecondary"  # Nome único global
  resource_group_name      = azurerm_resource_group.secondary.name
  location                 = azurerm_resource_group.secondary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"  # Redundância local
}

# Container na região primária
resource "azurerm_storage_container" "primary" {
  provider              = azurerm.brazilsouth
  name                  = "primary-container"
  storage_account_name  = azurerm_storage_account.primary.name
  container_access_type = "private"
}

# Container na região secundária
resource "azurerm_storage_container" "secondary" {
  provider              = azurerm.eastus
  name                  = "secondary-container"
  storage_account_name  = azurerm_storage_account.secondary.name
  container_access_type = "private"
}
