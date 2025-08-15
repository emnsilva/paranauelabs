provider "azurerm" {
  features {}
}

# Cria um grupo de recursos
resource "azurerm_resource_group" "main" {
  name     = "main-blob-storage"
  location = "brazilsouth"
}

# Cria a conta de armazenamento com o nome "paranaublob"
resource "azurerm_storage_account" "main" {
  name                     = "paranaublob"  # Nome alterado conforme solicitado
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"  # Localmente redundante
}

# Cria um container (similar a uma pasta no bucket S3)
resource "azurerm_storage_container" "main" {
  name                  = "main-container"
  storage_account_name  = azurerm_storage_account.main.name  # Referência corrigida
  container_access_type = "private"
}
