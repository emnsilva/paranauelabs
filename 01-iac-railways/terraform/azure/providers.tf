# providers.tf
# Configura a conexão com o Azure.

provider "azurerm" {
  features {}
  
  # O TFC injeta o subscription_id, client_id e tenant_id via OIDC nativo.
  # O Azure não suporta 'default_tags' no bloco do provider.
}