# Define quais "plugins" o Terraform precisa baixar e instalar
terraform {
  required_providers {
    # Provedor Azure - Microsoft Azure
    azurerm = {
      source  = "hashicorp/azurerm" # Fonte oficial da HashiCorp
      version = "~> 4.76.0"         # Versão aproximadamente 4.76.0
    }
    # Provedor Random - Para gerar nomes únicos globais
    random = {
      source  = "hashicorp/random"
      version = "~> 3.9.0"
    }
  }
}

# Cria um sufixo único para evitar conflitos de nomes globais da Microsoft
resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

# Variáveis de configuração Azure
variable "ARM_CLIENT_SECRET" {
  default = null
  type    = string
}
variable "ARM_PRIMARY_REGION" {}
variable "ARM_SECONDARY_REGION" {}

# Provedores Azure
provider "azurerm" {
  alias    = "primary"
  features {}
}

provider "azurerm" {
  alias    = "secondary"
  features {}
}

# Grupos de recursos Azure
resource "azurerm_resource_group" "primary" {
  name     = "primary-blob-storage"
  provider = azurerm.primary
  location = var.ARM_PRIMARY_REGION
}

resource "azurerm_resource_group" "secondary" {
  name     = "secondary-blob-storage"
  provider = azurerm.secondary
  location = var.ARM_SECONDARY_REGION
}

# Contas de armazenamento Azure
resource "azurerm_storage_account" "primary" {
  name                     = "primarystorage${random_string.suffix.result}" # Nome único global
  resource_group_name      = azurerm_resource_group.primary.name
  location                 = azurerm_resource_group.primary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  provider                 = azurerm.primary
}

resource "azurerm_storage_account" "secondary" {
  name                     = "secondarystorage${random_string.suffix.result}" # Nome único global
  resource_group_name      = azurerm_resource_group.secondary.name
  location                 = azurerm_resource_group.secondary.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
  provider                 = azurerm.secondary
}

# Containers BLOB Azure
resource "azurerm_storage_container" "primary" {
  name                  = "primary-container"
  storage_account_id    = azurerm_storage_account.primary.id
  container_access_type = "private"
  provider              = azurerm.primary
}

resource "azurerm_storage_container" "secondary" {
  name                  = "secondary-container"
  storage_account_id    = azurerm_storage_account.secondary.id
  container_access_type = "private"
  provider              = azurerm.secondary
}