# Cria storage accounts e containers em regiões primária e secundária

# Resource group primário
resource "azurerm_resource_group" "primary" {
  name     = "rg-${var.prefixo}-${var.ambiente}-primary"
  location = var.primary_region
  tags     = var.tags_globais
}

# Resource group secundário
resource "azurerm_resource_group" "secondary" {
  provider = azurerm.secondary
  name     = "rg-${var.prefixo}-${var.ambiente}-secondary"
  location = var.secondary_region
  tags     = var.tags_globais
}

# Storage account primária
resource "azurerm_storage_account" "primary" {
  name                     = lower("st${replace(var.prefixo, "-", "")}${var.ambiente}01")
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = var.tipo_conta
  account_replication_type = var.tipo_replicacao
  account_kind             = "StorageV2"
  
  # Segurança
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags = var.tags_globais
}

# Storage account secundária
resource "azurerm_storage_account" "secondary" {
  provider = azurerm.secondary
  name                     = lower("st${replace(var.prefixo, "-", "")}${var.ambiente}02")
  resource_group_name      = azurerm_resource_group.secondary.name
  location                 = azurerm_resource_group.secondary.location
  account_tier             = var.tipo_conta
  account_replication_type = var.tipo_replicacao
  account_kind             = "StorageV2"
  
  # Segurança
  https_traffic_only_enabled = true
  min_tls_version            = "TLS1_2"
  allow_nested_items_to_be_public = false
  tags = var.tags_globais
}

# Containers primários
resource "azurerm_storage_container" "primary_containers" {
  for_each = toset(var.nomes_containers)
  name                  = "${var.ambiente}-${each.value}"
  storage_account_id    = azurerm_storage_account.primary.id
  container_access_type = var.tipo_acesso_container
}

# # Containers secundários
resource "azurerm_storage_container" "secondary_containers" {
  for_each = toset(var.nomes_containers)
  provider = azurerm.secondary
  name                  = "${var.ambiente}-${each.value}"
  storage_account_id    = azurerm_storage_account.secondary.id
  container_access_type = var.tipo_acesso_container
}
