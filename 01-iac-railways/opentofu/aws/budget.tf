# budget.tf
# Configura o AWS Budgets para monitorar os custos do laboratório.
# O alerta é disparado quando o gasto atinge 80% do limite ($4,00).

resource "aws_budgets_budget" "paranauelabs" {
  # O AWS Budgets é um serviço global, mas a API exige que seja criado via us-east-1.
  # Por isso usamos o provider secondary aqui.
  provider = aws.secondary

  name              = "ParanaueLabs-Monthly-Budget-${var.environment}"
  budget_type       = "COST"
  limit_amount      = "5.00"
  limit_unit        = "USD"
  time_period_start = "2024-01-01_00:00"
  time_unit         = "MONTHLY"

  # Filtra os custos APENAS dos recursos deste projeto, usando a tag que 
  # você definiu no default_tags do providers.tf
  cost_filter {
    name = "TagKeyValue"
    values = [
      "Project$paranauelabs"
    ]
  }

  # Alerta por e-mail quando o gasto REAL (ACTUAL) ultrapassar 80% (ou seja, $4,00)
  notification {
    comparison_operator         = "GREATER_THAN"
    threshold                   = 80
    threshold_type              = "PERCENTAGE"
    notification_type           = "ACTUAL"
    subscriber_email_addresses  = ["emnsilva@outlook.com"] # 👈 TROQUE PELO SEU E-MAIL
  }
}