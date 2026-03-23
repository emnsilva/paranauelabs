# Variáveis de conexão dos providers (AWS, AZURE e GCP)

variable "AWS_REGION_PRIMARY" {
  description = "Região primária da AWS"
  type        = string
}

variable "AWS_REGION_SECONDARY" {
  description = "Região secundária da AWS"
  type        = string
}

variable "ARM_PRIMARY_REGION" { 
  description = "Região primária da Azure"
  type        = string
}

variable "ARM_SECONDARY_REGION" {
  description = "Região secundária da Azure"
  type        = string
}

variable "GCP_PROJECT" { 
  description = "Project ID do GCP"
  type        = string
}

variable "GCP_PRIMARY_REGION" { 
  description = "Região primária do GCP"
  type        = string 
}

variable "GCP_SECONDARY_REGION" { 
  description = "Região secundária do GCP"
  type        = string 
}

# Credenciais Estáticas (Apenas para GCP, pois foi definido como variável Terraform)
variable "GOOGLE_CREDENTIALS_B64" {
  description = "Credenciais do GCP codificadas em Base64 (do TFC)"
  type        = string
  sensitive   = true # Marca como sensível para não aparecer nos logs
  default     = null # Default nulo permite usar OIDC se a variável não vier do TFC
}

# Identidade e Governança

variable "project_prefix" {
  description = "Prefixo para nomear todos os recursos da ferrovia"
  type        = string
  default     = "TRR"
}

variable "environment" {
  description = "Ambiente de operação"
  type        = string
  default     = "production"
}

variable "global_tags" {
  description = "Tags aplicadas em todos os trilhos e estações"
  type        = map(string)
  default     = {
    projeto     = "terraform-railroad"
    gerenciado  = "Paranauê Labs"
    time        = "paranaue-engineering"
  }
}

# O mapa da ferrovia

variable "cities" {
  description = "Mapa das cidades replicadas nas regiões Principal e Backup"
  type = map(object({
    provider = string
    region   = string
    is_hq    = bool
    cidr     = string
  }))

  default = {
    
    # BLOCO 1: Região principal
    
    RIO_Primary   = { provider = "aws", region = "sa-east-1", is_hq = true,  cidr = "10.1.0.0/16" }
    SAO_Primary   = { provider = "aws", region = "sa-east-1", is_hq = false, cidr = "10.2.0.0/16" }
    BHZ_Primary   = { provider = "aws", region = "sa-east-1", is_hq = false, cidr = "10.3.0.0/16" }
    BSB_Primary   = { provider = "aws", region = "sa-east-1", is_hq = false, cidr = "10.4.0.0/16" }
    POA_Primary   = { provider = "aws", region = "sa-east-1", is_hq = false, cidr = "10.5.0.0/16" }
    SSA_Primary   = { provider = "aws", region = "sa-east-1", is_hq = false, cidr = "10.6.0.0/16" }
    REC_Primary   = { provider = "aws", region = "sa-east-1", is_hq = false, cidr = "10.7.0.0/16" }
    FOR_Primary   = { provider = "aws", region = "sa-east-1", is_hq = false, cidr = "10.8.0.0/16" }

    # BLOCO 2: Região de backup
    
    RIO_Backup    = { provider = "aws", region = "us-east-1", is_hq = true,  cidr = "10.9.0.0/16" }
    SAO_Backup    = { provider = "aws", region = "us-east-1", is_hq = false, cidr = "10.10.0.0/16" }
    BHZ_Backup    = { provider = "aws", region = "us-east-1", is_hq = false, cidr = "10.11.0.0/16" }
    BSB_Backup    = { provider = "aws", region = "us-east-1", is_hq = false, cidr = "10.12.0.0/16" }
    POA_Backup    = { provider = "aws", region = "us-east-1", is_hq = false, cidr = "10.13.0.0/16" }
    SSA_Backup    = { provider = "aws", region = "us-east-1", is_hq = false, cidr = "10.14.0.0/16" }
    REC_Backup    = { provider = "aws", region = "us-east-1", is_hq = false, cidr = "10.15.0.0/16" }
    FOR_Backup    = { provider = "aws", region = "us-east-1", is_hq = false, cidr = "10.16.0.0/16" }
  }
}