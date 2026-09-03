# O Object Storage exige saber o "Namespace" da tenancy.
data "oci_objectstorage_namespace" "lab_ns" {
  compartment_id = data.oci_identity_compartment.lab_compartment.id
}

# Bucket de Storage
resource "oci_objectstorage_bucket" "lab_bucket" {
  compartment_id = data.oci_identity_compartment.lab_compartment.id
  namespace      = data.oci_objectstorage_namespace.lab_ns.namespace
  name           = "paranauelabs-oci-${var.environment}"
  access_type    = "NoPublicAccess"
}