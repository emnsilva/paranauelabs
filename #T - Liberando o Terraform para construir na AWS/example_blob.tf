provider "azurerm" {
  features {}
}

# Grupo de recursos na região primária (Brazil South)
resource "azurerm_resource_group" "main_br" {
  name     = "main-blob-storage-br"
  location = "brazilsouth"
}

# Grupo de recursos na região secundária (East US)
resource "azurerm_resource_group" "main_us" {
  name     = "main-blob-storage-us"
  location = "eastus"
}

# Conta de armazenamento na região primária
resource "azurerm_storage_account" "main_br" {
  name                     = "paranaublobbr"  # Nome único para Brazil
  resource_group_name      = azurerm_resource_group.main_br.name
  location                 = azurerm_resource_group.main_br.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Conta de armazenamento na região secundária
resource "azurerm_storage_account" "main_us" {
  name                     = "paranaublobus"  # Nome único para East US
  resource_group_name      = azurerm_resource_group.main_us.name
  location                 = azurerm_resource_group.main_us.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Container na região primária
resource "azurerm_storage_container" "main_br" {
  name                  = "main-container-br"
  storage_account_id  = azurerm_storage_account.main_br.name
  container_access_type = "private"
}

# Container na região secundária
resource "azurerm_storage_container" "main_us" {
  name                  = "main-container-us"
  storage_account_id  = azurerm_storage_account.main_us.name
  container_access_type = "private"
}
