# Central de configurações para toda a infraestrutura multi-cloud
# Todas as variáveis são passadas explicitamente para máxima clareza

# 1. Identidade do projeto
variable "PREFIXO_PROJETO" {
  description = "Prefixo usado para nomear todos os recursos da infraestrutura"
  type        = string
  default     = "tfa"
  
  validation {
    condition     = length(var.PREFIXO_PROJETO) >= 3 && length(var.PREFIXO_PROJETO) <= 20
    error_message = "Prefixo deve ter entre 3 e 20 caracteres."
  }
}

variable "ENVIRONMENT" {
  description = "Ambiente de implantação que define configurações de segurança e custo"
  type        = string
  default     = "dev"
  
  validation {
    condition     = contains(["dev", "staging", "production"], var.ENVIRONMENT)
    error_message = "Ambiente deve ser: dev, staging ou production."
  }
}

# 2. Governança multicloud (Tags globais)
variable "TAGS_GLOBAIS" {
  description = "Tags padronizadas aplicadas a TODOS os recursos nos três provedores"
  type        = map(string)
  default     = {
    # Identificação básica
    projeto     = "terraform-airlines"
    ambiente    = "dev"
    
    # Responsabilidade
    time        = "cloud-engineering"
    gerenciado  = "terraform"
    responsavel = "equipe-devops"
    
    # Metadados do projeto
    artigo      = "hangar-modulos"
    versao      = "1.0.0"
    criado-em   = formatdate("YYYY-MM-DD", timestamp())
    
    # Gestão
    custo       = "infraestrutura"
    prioridade  = "medium"
    compliance  = "standard"
  }
}

# 3. Configurações AWS
variable "AWS_REGION_PRIMARY" {
  description = "Região primária da AWS para recursos de produção"
  type        = string
}

variable "AWS_REGION_SECONDARY" {
  description = "Região secundária da AWS para disaster recovery"
  type        = string
}

# 4. Configurações AZURE
variable "ARM_PRIMARY_REGION" {
  description = "Região primária do Azure para recursos principais"
  type        = string
}

variable "ARM_SECONDARY_REGION" {
  description = "Região secundária do Azure para alta disponibilidade"
  type        = string
}

# 5. Configurações GCP
variable "GCP_PROJECT" {
  description = "ID único do projeto Google Cloud Platform"
  type        = string
}

variable "GCP_PRIMARY_REGION" {
  description = "Região primária do GCP para armazenamento"
  type        = string
}

variable "GCP_SECONDARY_REGION" {
  description = "Região secundária do GCP para redundância"
  type        = string
}

# 6. Credenciais para autenticação estática (Opcional)
# Estas variáveis são usadas apenas quando não há OIDC configurado
# Em produção com OIDC, permanecem como null

variable "GOOGLE_CREDENTIALS_B64" {
  description = "Credenciais de serviço GCP codificadas em base64 - APENAS para autenticação estática"
  type        = string
  default     = null
  sensitive   = true
}

variable "ARM_CLIENT_SECRET" {
  description = "Client Secret do Azure Active Directory - APENAS para autenticação estática"
  type        = string
  default     = null
  sensitive   = true
}

# 7. Outputs das variáveis configuradas (Opcional - para verificação)
output "configuracao_projeto" {
  description = "Resumo da configuração do projeto"
  value = {
    projeto     = var.PREFIXO_PROJETO
    ambiente    = var.ENVIRONMENT
    total_tags  = length(var.TAGS_GLOBAIS)
  }
  sensitive = false
}

output "regioes_configuradas" {
  description = "Regiões configuradas em cada provedor"
  value = {
    aws = {
      primary   = var.AWS_REGION_PRIMARY
      secondary = var.AWS_REGION_SECONDARY
    }
    azure = {
      primary   = var.ARM_PRIMARY_REGION
      secondary = var.ARM_SECONDARY_REGION
    }
    gcp = {
      primary   = var.GCP_PRIMARY_REGION
      secondary = var.GCP_SECONDARY_REGION
    }
  }
  sensitive = false
}