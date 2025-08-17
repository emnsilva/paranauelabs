variable "ARM_PRIMARY_REGION" {}
variable "ARM_SECONDARY_REGION" {}

# Configuração flexível (OIDC vs estático)
  use_oidc = lookup(env(), "ARM_USE_OIDC", "false") == "true" ? true : false
  
  # Se OIDC estiver desativado, tenta credenciais estáticas
  client_id     = lookup(env(), "ARM_USE_OIDC", "false") == "true" ? null : lookup(env(), "ARM_CLIENT_ID", null)
  client_secret = lookup(env(), "ARM_USE_OIDC", "false") == "true" ? null : lookup(env(), "ARM_CLIENT_SECRET", null)
  
  # Configurações comuns (pode ser via env ou hardcoded)
  subscription_id = lookup(env(), "ARM_SUBSCRIPTION_ID", "seu-subscription-id")
  tenant_id       = lookup(env(), "ARM_TENANT_ID", "seu-tenant-id")
}

# Seus recursos originais (sem alterações)
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
