# CONFIGURAÇÃO DO BACKEND REMOTO
# Define onde o Terraform armazena o arquivo de estado
# O estado é um arquivo JSON que guarda o mapa completo da infraestrutura
# Para cada pasta (AWS, Azure ou GCP), você precisa ter uma cópia desse arquivo
terraform {
  backend "remote" {
    hostname     = "app.terraform.io"           # Serviço do Terraform Cloud
    organization = "NOME_DA_ORGANIZAÇÃO"        # Nome da organização no Terraform Cloud

    workspaces {
      prefix = "aws_"                          # Busca todos workspaces que começam com "aws_"
    }
  }
}
