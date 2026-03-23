# Conecta o código local ao Terraform Cloud.
terraform {
  cloud {
    organization = "NOME_DA_SUA_ORGANIZACAO" # Ex: Paranaue Labs

    workspaces {
      # O Terraform vai procurar workspaces que comecem com "gate_".      
      prefix = "gate-"
    }
  }
}