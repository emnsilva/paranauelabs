# VCN (Virtual Cloud Network)
resource "oci_core_vcn" "lab_vcn" {
  compartment_id = data.oci_identity_compartment.lab_compartment.id
  display_name   = "vcn-${var.environment}"
  cidr_block     = "10.0.0.0/16"
}

# Subnet
resource "oci_core_subnet" "lab_subnet" {
  compartment_id = data.oci_identity_compartment.lab_compartment.id
  vcn_id         = oci_core_vcn.lab_vcn.id
  cidr_block     = "10.0.1.0/24"
  display_name   = "subnet-${var.environment}"
}

# Security List (Equivalente ao Security Group)
resource "oci_core_security_list" "lab_sl" {
  compartment_id = data.oci_identity_compartment.lab_compartment.id
  vcn_id         = oci_core_vcn.lab_vcn.id
  display_name   = "sl-${var.environment}"

  # Libera HTTP
  ingress_security_rules {
    source   = "0.0.0.0/0"
    protocol = "6"
    tcp_options {
      min = 80
      max = 80
    }
  }
}