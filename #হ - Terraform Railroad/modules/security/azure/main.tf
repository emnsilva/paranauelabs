# 1. AS CANCELAS (Network Security Group)
resource "azurerm_network_security_group" "this" {
  name                = "nsg-${var.city_name}"
  location            = var.location
  resource_group_name = var.resource_group_name

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
  tags = var.tags
}

# 2. ASSOCIAÇÃO (Conectando a Cancela ao Trilho)
resource "azurerm_subnet_network_security_group_association" "this" {
  count                     = length(var.subnet_ids)
  subnet_id                 = var.subnet_ids[count.index]
  network_security_group_id = azurerm_network_security_group.this.id
}