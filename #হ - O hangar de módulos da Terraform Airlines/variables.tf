variable "AWS_REGION_PRIMARY" {}
variable "AWS_REGION_SECONDARY" {}
variable "GCP_PROJECT" {}
variable "GCP_PRIMARY_REGION" {}
variable "GCP_SECONDARY_REGION" {}
variable "ARM_PRIMARY_REGION" {}
variable "ARM_SECONDARY_REGION" {}
variable "ARM_SUBSCRIPTION_ID" {}
variable "ARM_CLIENT_ID" {}
variable "ARM_CLIENT_SECRET" { sensitive = true }
variable "ARM_TENANT_ID" {}