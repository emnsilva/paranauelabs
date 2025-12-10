variable "project_id" {
  description = "ID do projeto GCP onde os buckets serão criados"
  type        = string
}

variable "ambiente" {
  description = "Ambiente (dev, staging, production)"
  type        = string
}

variable "primary_region" {
  description = "Região primária para o bucket principal"
  type        = string
}

variable "secondary_region" {
  description = "Região secundária para o bucket secundário"
  type        = string
}

variable "classe_armazenamento" {
  description = "Classe de armazenamento (STANDARD, NEARLINE, etc.)"
  type        = string
  default     = "STANDARD"
}

variable "habilitar_versionamento" {
  description = "Controla se o versionamento de objetos fica habilitado"
  type        = bool
  default     = true
}

variable "acesso_uniforme" {
  description = "Força acesso uniforme no nível do bucket"
  type        = bool
  default     = true
}

variable "regras_lifecycle" {
  description = "Mapa de regras de lifecycle aplicadas aos buckets"
  type = map(object({
    acao_tipo              = string
    acao_classe            = optional(string)
    condicao_idade         = optional(number)
    condicao_estado        = optional(string)
    condicao_classe        = optional(list(string))
    condicao_versoes_novas = optional(number)
  }))
  default = {}
}

variable "tags_globais" {
  description = "Tags globais convertidas para labels nos buckets"
  type        = map(string)
}

