# VARIÁVEIS DE CONFIGURAÇÃO AZURE
# Define credenciais e regiões para o Microsoft Azure
# ARM_CLIENT_SECRET é a senha de autenticação do Azure
variable "ARM_CLIENT_SECRET" {
  default = null   # Pode ser nulo se usar outras formas de autenticação
  type    = string # Tipo texto
}
variable "ARM_PRIMARY_REGION" {}       # Região primária (ex: eastus)
variable "ARM_SECONDARY_REGION" {}     # Região secundária (ex: westus)

# PROVEDORES AZURE
# Configura conexões com o Azure Resource Manager
# Cada provider representa uma conexão com o Azure
provider "azurerm" {
  features {}                          # Configuração padrão de features do Azure
}

provider "azurerm" {
  alias  = "primary"                   # Apelido para região primária
  features {}                          # Configuração padrão
}

provider "azurerm" {
  alias  = "secondary"                 # Apelido para região secundária
  features {}                          # Configuração padrão
}

# GRUPOS DE RECURSOS AZURE
# Cria "pastas organizadoras" para agrupar recursos relacionados
# Cada região tem seu próprio grupo de recursos
resource "azurerm_resource_group" "primary" {
  name     = "primary-blob-storage"    # Nome do grupo de recursos
  provider = azurerm.primary           # Usa provider da região primária
  location = var.ARM_PRIMARY_REGION    # Localização do grupo de recursos
}

resource "azurerm_resource_group" "secondary" {
  name     = "secondary-blob-storage"  # Nome do grupo de recursos
  provider = azurerm.secondary         # Usa provider da região secundária
  location = var.ARM_SECONDARY_REGION  # Localização do grupo de recursos
}

# CONTAS DE ARMAZENAMENTO AZURE
# Cria "caixas de arquivos" para armazenamento Blob
# Cada conta tem configurações de tipo e replicação
resource "azurerm_storage_account" "primary" {
  name                     = "primarystorage"                           # Nome único global
  resource_group_name      = azurerm_resource_group.primary.name        # Link com grupo
  location                 = azurerm_resource_group.primary.location    # Localização
  account_tier             = "Standard"                                 # Tipo de conta (Standard/Premium)
  account_replication_type = "LRS"                                      # Replicação Localmente Redundante
}

resource "azurerm_storage_account" "secondary" {
  name                     = "secondarystorage"                         # Nome único global
  resource_group_name      = azurerm_resource_group.secondary.name      # Link com grupo
  location                 = azurerm_resource_group.secondary.location  # Localização
  account_tier             = "Standard"                                 # Tipo de conta
  account_replication_type = "LRS"                                      # Replicação Localmente Redundante
}

# CONTAINERS BLOB AZURE
# Cria "gavetas" dentro das contas de armazenamento
# São onde os arquivos são realmente armazenados
resource "azurerm_storage_container" "primary" {
  name                  = "primary-container"                           # Nome do container
  storage_account_id    = azurerm_storage_account.primary.id            # Link com conta
  container_access_type = "private"                                     # Acesso apenas com autenticação
}

resource "azurerm_storage_container" "secondary" {
  name                  = "secondary-container"                         # Nome do container
  storage_account_id    = azurerm_storage_account.secondary.id          # Link com conta
  container_access_type = "private"                                     # Acesso apenas com autenticação
}
