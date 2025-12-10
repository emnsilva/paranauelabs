variable "PREFIXO_PROJETO" {
  description = "Prefixo usado na composição dos nomes dos buckets"
  type        = string
}

variable "ENVIRONMENT" {
  description = "Ambiente atual (dev, staging, production)"
  type        = string
}

variable "TAGS_GLOBAIS" {
  description = "Tags aplicadas a todos os recursos S3"
  type        = map(string)
}

variable "habilitar_versionamento" {
  description = "Controla se o versionamento de objetos S3 fica habilitado"
  type        = bool
  default     = true
}

variable "regras_lifecycle" {
  description = "Mapa de regras de lifecycle aplicadas quando ambiente for production"
  type = map(object({
    dias_expiracao = number
    prefixo        = string
  }))
  default = {
    logs = { dias_expiracao = 90, prefixo = "logs/" }
    temp = { dias_expiracao = 7,  prefixo = "temp/" }
  }
}

