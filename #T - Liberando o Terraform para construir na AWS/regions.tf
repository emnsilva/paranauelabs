locals {
  region_mapping = {
    primary = {
      gcp   = "southamerica-east1",
      azure = "brazilsouth",
      aws   = "sa-east-1"
    },
    secondary = {
      gcp   = "us-east1",
      azure = "eastus",
      aws   = "us-east-1"
    }
  }
}
