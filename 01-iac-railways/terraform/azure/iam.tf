# iam.tf
# Provisionamento de Identidade (Managed Identities)
# Criação de User Assigned Identities para as VMs.

# Identidade para a VM Primária
resource "azurerm_user_assigned_identity" "vm_identity_primary" {
  name                = "id-vm-primary-${var.environment}"
  resource_group_name = azurerm_resource_group.rg_primary.name
  location            = azurerm_resource_group.rg_primary.location
}

# Identidade para a VM Secundária
resource "azurerm_user_assigned_identity" "vm_identity_secondary" {
  name                = "id-vm-secondary-${var.environment}"
  resource_group_name = azurerm_resource_group.rg_secondary.name
  location            = azurerm_resource_group.rg_secondary.location
}

# Atribuição de papel (Role Assignment) - Least Privilege
# Dá permissão para a VM escrever no Storage Account respectivo
resource "azurerm_role_assignment" "vm_storage_primary" {
  scope                = azurerm_storage_account.storage_primary.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.vm_identity_primary.principal_id
}

resource "azurerm_role_assignment" "vm_storage_secondary" {
  scope                = azurerm_storage_account.storage_secondary.id
  role_definition_name = "Storage Blob Data Contributor"
  principal_id         = azurerm_user_assigned_identity.vm_identity_secondary.principal_id
}