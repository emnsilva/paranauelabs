variable "environment" {
  description = "Nome do ambiente (ex: dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "OCI_REGION" {
  description = "Região da Oracle Cloud (ex: sa-saopaulo-1)."
  type        = string
  default     = "sa-saopaulo-1"
}

# As variáveis abaixo NÃO têm 'default' porque são sensíveis e virão do TFC.
# No TFC, crie-as com os nomes: OCI_TENANCY_OCID, OCI_USER_OCID, OCI_FINGERPRINT, OCI_PRIVATE_KEY
variable "OCI_TENANCY_OCID" { type = string }
variable "OCI_USER_OCID" { type = string }
variable "OCI_FINGERPRINT" { type = string }
variable "OCI_PRIVATE_KEY" { type = string }