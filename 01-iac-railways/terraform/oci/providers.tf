# O provider da Oracle lê as variáveis de ambiente (TF_VAR_tenancy_ocid, etc)
# que serão injetadas pelo Variable Set do Terraform Cloud.

provider "oci" {
  tenancy_ocid = var.tenancy_ocid
  user_ocid    = var.user_ocid
  fingerprint  = var.fingerprint
  private_key  = var.private_key
  region       = var.region
}

data "oci_identity_compartment" "lab_compartment" {
  id = var.tenancy_ocid
}