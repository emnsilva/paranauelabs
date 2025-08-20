# ARQUIVO: backend.tf
# FINALIDADE: Configura onde o Terraform armazena o "estado" da infraestrutura

terraform {
  # Configura o backend remoto - onde o estado será armazenado
  backend "remote" {
    # Usa o Terraform Cloud da HashiCorp
    hostname = "app.terraform.io"
    
    # Nome da sua organização no Terraform Cloud
    organization = "NOME_DA_ORGANIZAÇÃO"

    # Configuração dos workspaces (ambientes de trabalho)
    workspaces {
      # Prefixo para identificar workspaces - buscará TODOS que começam com "gate_"
      prefix = "gate_" 
    }
  }
}
