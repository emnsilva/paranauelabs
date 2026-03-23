variable "vpc_name" {
  description = "Nome da VPC para associar as regras de firewall"
  type        = string
}

variable "project_id" {
  type = string
}

variable "city_name" {
  type = string
}

variable "tags" {
  type    = map(string)
  default = {}
}