# CONFIGURAÇÃO DO BACKEND REMOTO
# Define onde o Terraform armazena o arquivo de estado
# O estado é um arquivo JSON que guarda o mapa completo da infraestrutura
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"           # Serviço do Terraform Cloud
    organization = "NOME_DA_ORGANIZAÇÃO"        # Nome da organização no Terraform Cloud

    workspaces {
      prefix = "gate_"                          # Busca todos workspaces que começam com "gate_"
    }
  }
}
