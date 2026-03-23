# Define os insumos para construir uma VNet (Virtual Network) no Azure.
# Nota: No Azure, recursos precisam pertencer a um Resource Group.

# 1. Identificação
variable "city_name" {
  description = "Nome da cidade"
  type        = string
}

# 2. Localização e Grupo
variable "location" {
  description = "A região Azure (ex: brazilsouth)"
  type        = string
}

variable "resource_group_name" {
  description = "Nome do Resource Group onde a via será criada"
  type        = string
}

# 3. Dimensionamento da Rede
variable "vnet_cidr" {
  description = "Endereço da VNet (Virtual Network)"
  type        = string
}

# 4. Governança
variable "tags" {
  description = "Tags do recurso"
  type        = map(string)
  default     = {}
}