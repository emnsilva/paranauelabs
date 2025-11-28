# Essas variáveis são necessárias independente do método de autenticação

# Variáveis AWS
variable "AWS_REGION_PRIMARY" {
  description = "Região primária da AWS (ex: us-east-1, sa-east-1)"
  type        = string
}

variable "AWS_REGION_SECONDARY" {
  description = "Região secundária da AWS (ex: us-west-2, us-east-1)"
  type        = string
}

# Variáveis Azure
variable "ARM_PRIMARY_REGION" {
  description = "Região primária do Azure (ex: eastus, brazilsouth)"
  type        = string
}

variable "ARM_SECONDARY_REGION" {
  description = "Região secundária do Azure (ex: westus, eastus)"
  type        = string
}

# Variáveis GCP
variable "GCP_PROJECT" {
  description = "ID do projeto do Google Cloud Platform"
  type        = string
}

variable "GCP_PRIMARY_REGION" {
  description = "Região primária do GCP (ex: us-central1, southamerica-east1)"
  type        = string
}

variable "GCP_SECONDARY_REGION" {
  description = "Região secundária do GCP (ex: europe-west1, us-east1)"
  type        = string
}

# Variáveis opcionais para credenciais estáticas
# Essas variáveis são ignoradas quando se usa OIDC
variable "GOOGLE_CREDENTIALS_B64" {
  description = "Credenciais do GCP em base64 (apenas para autenticação estática)"
  type        = string
  default     = null
  sensitive   = true
}

variable "ARM_CLIENT_SECRET" {
  description = "Client Secret do Azure (apenas para autenticação estática)"
  type        = string
  default     = null
  sensitive   = true
}