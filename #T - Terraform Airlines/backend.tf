terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "NOME_DA_ORGANIZAÇÃO"

    workspaces {
      prefix = "gate_" # Busca TODOS os workspaces que começam com "gate-"
    }
  }
}
