# variables.tf - Declaração de todas as variáveis de entrada do projeto

# =================== AWS ===================
variable "AWS_REGION_PRIMARY" {
  description = "Região primária da AWS (ex: us-east-1)"
  type        = string
}
variable "AWS_REGION_SECONDARY" {
  description = "Região secundária da AWS (ex: us-west-2)"
  type        = string
}

# =================== GCP ===================
variable "GCP_PROJECT" {
  description = "ID do projeto no Google Cloud"
  type        = string
}
variable "GCP_PRIMARY_REGION" {
  description = "Região primária do GCP (ex: us-central1)"
  type        = string
}
variable "GCP_SECONDARY_REGION" {
  description = "Região secundária do GCP (ex: europe-west1)"
  type        = string
}
variable "GOOGLE_CREDENTIALS_B64" {
  description = "Credenciais do Google Cloud em base64"
  type        = string
  sensitive   = true
}

# =================== Azure ===================
variable "ARM_PRIMARY_REGION" {
  description = "Região primária do Azure (ex: eastus)."
  type        = string
}
variable "ARM_SECONDARY_REGION" {
  description = "Região secundária do Azure (ex: westus)."
  type        = string
}

# As credenciais do Azure são frequentemente passadas como variáveis de ambiente,
# mas se você as configurou como 'Terraform Variables' no TFC, elas também precisam ser declaradas.
variable "ARM_CLIENT_ID" {
  description = "Client ID para autenticação no Azure."
  type        = string
  sensitive   = true
}
variable "ARM_CLIENT_SECRET" {
  description = "Client Secret para autenticação no Azure."
  type        = string
  sensitive   = true
}
variable "ARM_SUBSCRIPTION_ID" {
  description = "Subscription ID da conta Azure."
  type        = string
  sensitive   = true
}
variable "ARM_TENANT_ID" {
  description = "Tenant ID do diretório Azure."
  type        = string
  sensitive   = true
}
