# Devido a uma limitação do Terraform (providers não podem ser dinâmicos), usamos a estratégia de "Blocos Separados".
# Cada bloco usa um provider fixo (Primary ou Secondary) e filtra as cidades.

# BLOCO 1: Região principal
module "network_primary" {
  source = "../../modules/networking/aws"
  
  # Conecta este bloco ao canal 'primary' definido no provider.tf
  providers = {
    aws = aws.primary
  }

  # Filtro Inteligente:
  # Seleciona APENAS as cidades onde a região é igual à var.AWS_REGION_PRIMARY (definida no TFC).
  # Isso garante que, se o TFC apontar para 'sa-east-1', pegaremos apenas as cidades criadas lá.
  for_each = {
    for key, value in var.cities : key => value
    if value.region == var.AWS_REGION_PRIMARY
  }

  # Passando os dados do mapa para o módulo
  city_name       = each.key
  vpc_cidr        = each.value.cidr
  is_headquarters = each.value.is_hq
  aws_region      = each.value.region
  
  # Mescla tags globais com tags específicas deste recurso
  tags = merge(var.global_tags, {
    Environment = var.environment
    City        = each.key
    Role        = "Primary"
  })
}

# BLOCO 2: Região de backup
module "network_secondary" {
  source = "../../modules/networking/aws"

  # Conecta este bloco ao canal 'secondary' definido no provider.tf
  providers = {
    aws = aws.secondary
  }

  # Filtro Inteligente:
  # Seleciona APENAS as cidades onde a região é igual à var.AWS_REGION_SECONDARY (definida no TFC).
  for_each = {
    for key, value in var.cities : key => value
    if value.region == var.AWS_REGION_SECONDARY
  }

  # Passando os dados
  city_name       = each.key
  vpc_cidr        = each.value.cidr
  is_headquarters = each.value.is_hq
  aws_region      = each.value.region
  
  tags = merge(var.global_tags, {
    Environment = var.environment
    City        = each.key
    Role        = "Backup"
  })
}