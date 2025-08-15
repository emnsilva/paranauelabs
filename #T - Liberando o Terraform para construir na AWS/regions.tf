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

variable "CLOUD_PRIMARY_REGION" {
  type        = string
  description = "Alias para região primária (primary/secondary)"
  default     = "primary"
}

variable "CLOUD_SECONDARY_REGION" {
  type        = string
  description = "Alias para região secundária (primary/secondary)"
  default     = "secondary"
}
