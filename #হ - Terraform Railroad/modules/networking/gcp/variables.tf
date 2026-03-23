# Define os insumos para construir uma VPC no Google Cloud.
# Nota: O GCP organiza a rede em VPCs globais e Subnets regionais.

# 1. Identificação
variable "city_name" {
  description = "Nome da cidade"
  type        = string
}

# 2. Projeto e Localização
variable "project_id" {
  description = "ID do projeto GCP"
  type        = string
}

variable "region" {
  description = "A região GCP (ex: southamerica-east1)"
  type        = string
}

# 3. Dimensionamento da Rede
variable "vpc_name" {
  description = "Nome da VPC"
  type        = string
}

variable "subnet_cidr" {
  description = "Range de IP para a subnet principal"
  type        = string
}

# 4. Governança
variable "labels" {
  description = "Labels (tags) do GCP"
  type        = map(string)
  default     = {}
}