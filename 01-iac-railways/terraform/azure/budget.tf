# budget.tf

# Pega o ID completo da assinatura automaticamente
data "azurerm_subscription" "current" {}

resource "azurerm_consumption_budget_subscription" "paranauelabs" {
  name            = "ParanaueLabs-Monthly-Budget-${var.environment}"
  subscription_id = data.azurerm_subscription.current.id

  amount     = 5
  time_grain = "Monthly"

    time_period {
    start_date = "2026-09-02T00:00:00Z"
  }
  notification {
    enabled   = true
    threshold = 80.0
    operator  = "GreaterThan"

    contact_emails = ["emnsilva@outlook.com"]
  }
}