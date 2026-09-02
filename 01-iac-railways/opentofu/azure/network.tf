# network.tf
# Provisionamento da Rede (VNet, Subnets e NSGs)
# Nas duas regiões: Primária e Secundária (DR)

# 1. REDE REGIÃO PRIMÁRIA

resource "azurerm_resource_group" "rg_primary" {
  name     = "rg-paranauelabs-primary-${var.environment}"
  location = var.ARM_PRIMARY_REGION
}

resource "azurerm_virtual_network" "vnet_primary" {
  name                = "vnet-primary-${var.environment}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_primary.location
  resource_group_name = azurerm_resource_group.rg_primary.name
}

resource "azurerm_subnet" "subnet_primary" {
  name                 = "subnet-primary-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg_primary.name
  virtual_network_name = azurerm_virtual_network.vnet_primary.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Security Groups (Least Privilege)
resource "azurerm_network_security_group" "nsg_web_primary" {
  name                = "nsg-web-primary-${var.environment}"
  location            = azurerm_resource_group.rg_primary.location
  resource_group_name = azurerm_resource_group.rg_primary.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "AllowHTTPS"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "nsg_compute_primary" {
  name                = "nsg-compute-primary-${var.environment}"
  location            = azurerm_resource_group.rg_primary.location
  resource_group_name = azurerm_resource_group.rg_primary.name

  # No Azure, a referência cruzada é feita via IP ou tags. 
  # Para o laboratório, liberamos SSH apenas da subnet pública (Web).
  security_rule {
    name                       = "AllowSSHFromWeb"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "10.0.1.0/24"
    destination_address_prefix = "*"
  }
}

# Associação dos NSGs às Subnets
resource "azurerm_subnet_network_security_group_association" "web_primary" {
  subnet_id                 = azurerm_subnet.subnet_primary.id
  network_security_group_id = azurerm_network_security_group.nsg_web_primary.id
}

# 2. REDE REGIÃO SECUNDÁRIA (DR)

resource "azurerm_resource_group" "rg_secondary" {
  name     = "rg-paranauelabs-secondary-${var.environment}"
  location = var.ARM_SECONDARY_REGION
}

resource "azurerm_virtual_network" "vnet_secondary" {
  name                = "vnet-secondary-${var.environment}"
  address_space       = ["10.1.0.0/16"]
  location            = azurerm_resource_group.rg_secondary.location
  resource_group_name = azurerm_resource_group.rg_secondary.name
}

resource "azurerm_subnet" "subnet_secondary" {
  name                 = "subnet-secondary-${var.environment}"
  resource_group_name  = azurerm_resource_group.rg_secondary.name
  virtual_network_name = azurerm_virtual_network.vnet_secondary.name
  address_prefixes     = ["10.1.1.0/24"]
}

resource "azurerm_network_security_group" "nsg_web_secondary" {
  name                = "nsg-web-secondary-${var.environment}"
  location            = azurerm_resource_group.rg_secondary.location
  resource_group_name = azurerm_resource_group.rg_secondary.name

  security_rule {
    name                       = "AllowHTTP"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "web_secondary" {
  subnet_id                 = azurerm_subnet.subnet_secondary.id
  network_security_group_id = azurerm_network_security_group.nsg_web_secondary.id
}