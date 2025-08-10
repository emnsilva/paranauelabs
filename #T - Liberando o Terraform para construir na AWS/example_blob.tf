provider "azurerm" {
  features {}
}

# Cria um grupo de recursos
resource "azurerm_resource_group" "main" {
  name     = "main-blob-storage"
  location = "brazilsouth"
}

# Cria a conta de armazenamento (equivalente ao bucket S3)
resource "azurerm_storage_account" "example" {
  name                     = "main"  # Nome deve ser único globalmente
  resource_group_name      = azurerm_resource_group.main.name
  location                 = azurerm_resource_group.main.location
  account_tier             = "Standard"
  account_replication_type = "LRS"  # Localmente redundante
}

# Cria um container (similar a uma pasta no bucket S3)
resource "azurerm_storage_container" "main" {
  name                  = "main-container"
  storage_account_name  = azurerm_storage_account.main.name
  container_access_type = "private"  # Pode ser "blob" ou "container" para acesso público
}
