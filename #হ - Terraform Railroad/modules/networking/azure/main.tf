# 1. O TERRENO (Resource Group)
resource "azurerm_resource_group" "this" {
  name     = "rg-${var.city_name}"
  location = var.location
  tags     = var.tags
}

# 2. A MALHA FERROVIÁRIA (Virtual Network)
resource "azurerm_virtual_network" "this" {
  name                = "vnet-${var.city_name}"
  location            = azurerm_resource_group.this.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = [var.vnet_cidr]
  tags                = var.tags
}

# 3. TRILHOS PADRÃO (Subnets)
resource "azurerm_subnet" "standard" {
  count                = 2
  name                 = "subnet-padrao-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, count.index)]
}

# 4. TRILHOS EXCLUSIVOS DA SEDE (Condicional)
# Aplicando a mesma lógica de expansão da AWS.
resource "azurerm_subnet" "hq_extra" {
  count                = var.is_headquarters ? 2 : 0

  name                 = "subnet-sede-extra-${count.index + 1}"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = [cidrsubnet(var.vnet_cidr, 8, count.index + 10)]
}