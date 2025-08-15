# Grupo de recursos na região primária
resource "azurerm_resource_group" "main_br" {
  name     = "main-blob-storage-br"
  location = local.region_mapping[var.PRIMARY_REGION_ALIAS].azure
}

# Grupo de recursos na região secundária
resource "azurerm_resource_group" "main_us" {
  name     = "main-blob-storage-us"
  location = local.region_mapping[var.SECONDARY_REGION_ALIAS].azure
}

# Conta de armazenamento na região primária
resource "azurerm_storage_account" "main_br" {
  name                     = "paranaublobbr"
  resource_group_name      = azurerm_resource_group.main_br.name
  location                 = azurerm_resource_group.main_br.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Conta de armazenamento na região secundária
resource "azurerm_storage_account" "main_us" {
  name                     = "paranaublobus"
  resource_group_name      = azurerm_resource_group.main_us.name
  location                 = azurerm_resource_group.main_us.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

# Containers (já atualizados para usar storage_account_id)
resource "azurerm_storage_container" "main_br" {
  name                  = "main-container-br"
  storage_account_id    = azurerm_storage_account.main_br.id
  container_access_type = "private"
}

resource "azurerm_storage_container" "main_us" {
  name                  = "main-container-us"
  storage_account_id    = azurerm_storage_account.main_us.id
  container_access_type = "private"
}
