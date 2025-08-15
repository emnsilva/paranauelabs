# regions.tf - Mapeamento básico de regiões por provedor
locals {
  regions = {
    aws = {
      southamerica = "sa-east-1"
      eastus       = "us-east-1"
    }
    azure = {
      southamerica = "brazilsouth"
      eastus       = "eastus"
    }
    gcp = {
      southamerica = "southamerica-east1"
      eastus      = "us-east4"
    }
  }
}
