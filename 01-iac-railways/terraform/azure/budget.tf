# budget.tf
# Configura o Azure Cost Management Budget para monitorar custos.

resource "azurerm_consumption_budget_subscription" "paranauelabs" {
  name            = "ParanaueLabs-Monthly-Budget-${var.environment}"
  subscription_id = var.ARM_SUBSCRIPTION_ID

  amount     = 5
  time_grain = "Monthly"

  time_period {
    start_date = "2024-01-01T00:00:00Z"
  }

  notification {
    enabled   = true
    threshold = 80.0
    operator  = "GreaterThan"

    contact_emails = ["emnsilva@outlook.com"]
  }
}