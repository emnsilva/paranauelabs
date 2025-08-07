# variables.tf: Define parâmetros padrão, valores aceitáveis e permite que a infraestrutura seja flexível e reutilizável.
# Configuração centralizada para todas as VPCs
variable "vpcs" {
  description = "Configuração unificada para todas as VPCs em diferentes regiões"
  type = map(object({
    region     = string  # Região AWS (ex: 'sa-east-1')
    cidr_block = string  # Faixa de IPs (ex: '10.0.0.0/16')
  }))
  
  default = {
    primary = {  # VPC principal de produção
      region     = "sa-east-1"
      cidr_block = "10.0.0.0/16"
    }
    backup = {   # VPC de backup
      region     = "us-east-1"
      cidr_block = "10.1.0.0/16"
    }
  }
}
