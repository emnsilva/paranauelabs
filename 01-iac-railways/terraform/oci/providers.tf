# O provider da Oracle lê as variáveis de ambiente (TF_VAR_tenancy_ocid, etc)
# que serão injetadas pelo Variable Set do Terraform Cloud.

provider "oci" {
  tenancy_ocid = var.TENANCY_OCID
  user_ocid    = var.OCI_USER_OCID
  fingerprint  = var.OCI_FINGERPRINT
  private_key  = var.OCI_PRIVATE_KEY
  region       = var.OCI_REGION
}

data "oci_identity_compartment" "lab_compartment" {
  id = var.TENANCY_OCID
}