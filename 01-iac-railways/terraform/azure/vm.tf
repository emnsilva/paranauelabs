# vm.tf
# Provisionamento de Computação (Linux Virtual Machines)

# VM na Região PRIMÁRIA (Standard_B1s é a mais barata / FinOps)
resource "azurerm_linux_virtual_machine" "vm_primary" {
  name                            = "vm-primary-${var.ENVIRONMENT}"
  resource_group_name             = azurerm_resource_group.rg_primary.name
  location                        = azurerm_resource_group.rg_primary.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nic_primary.id,
  ]

  # Chave SSH (Para laboratório, pode gerar uma ou usar uma fixa)
  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/w...LAB_PUBLIC_KEY..."
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm_identity_primary.id]
  }
}

# Network Interface Primária
resource "azurerm_network_interface" "nic_primary" {
  name                = "nic-primary-${var.ENVIRONMENT}"
  location            = azurerm_resource_group.rg_primary.location
  resource_group_name = azurerm_resource_group.rg_primary.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_primary.id
    private_ip_address_allocation = "Dynamic"
  }
}

# VM na Região SECUNDÁRIA (DR)
resource "azurerm_linux_virtual_machine" "vm_secondary" {
  name                            = "vm-secondary-${var.ENVIRONMENT}"
  resource_group_name             = azurerm_resource_group.rg_secondary.name
  location                        = azurerm_resource_group.rg_secondary.location
  size                            = "Standard_B1s"
  admin_username                  = "adminuser"
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.nic_secondary.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQC/w...LAB_PUBLIC_KEY..."
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  identity {
    type         = "UserAssigned"
    identity_ids = [azurerm_user_assigned_identity.vm_identity_secondary.id]
  }
}

resource "azurerm_network_interface" "nic_secondary" {
  name                = "nic-secondary-${var.ENVIRONMENT}"
  location            = azurerm_resource_group.rg_secondary.location
  resource_group_name = azurerm_resource_group.rg_secondary.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.subnet_secondary.id
    private_ip_address_allocation = "Dynamic"
  }
}