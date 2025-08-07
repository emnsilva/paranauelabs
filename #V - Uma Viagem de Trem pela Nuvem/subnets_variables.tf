# Configurações para subnets públicas (customizáveis por ambiente)
regions = {
  main   = "sa-east-1"  # Região da VPC principal
  backup = "us-east-1"  # Região da VPC de backup
}

# Nomes das VPCs (devem bater com as tags 'Name' das VPCs existentes)
vpc_names = {
  main   = "main"    # Nome da VPC principal
  backup = "backup"  # Nome da VPC secundária
}

# Modelo das 8 subnets públicas (padrão para ambas VPCs)
subnets_public = [
  # Subnets públicas - Zona A
  { az_suffix = "a", cidr_index = 1 },  # 10.x.1.0/24
  { az_suffix = "b", cidr_index = 2 },  # 10.x.2.0/24
  { az_suffix = "c", cidr_index = 3 },  # 10.x.3.0/24
  { az_suffix = "d", cidr_index = 4 },  # 10.x.4.0/24
  
  # Subnets públicas - Zona B (redundância)
  { az_suffix = "e", cidr_index = 5 },  # 10.x.5.0/24
  { az_suffix = "f", cidr_index = 6 },  # 10.x.6.0/24
  { az_suffix = "g", cidr_index = 7 },  # 10.x.7.0/24
  { az_suffix = "h", cidr_index = 8 }   # 10.x.8.0/24
]

# ⚠️ Observações:
# 1. Os CIDRs serão:
#    - Main:   10.0.1.0/24 a 10.0.8.0/24
#    - Backup: 10.1.1.0/24 a 10.1.8.0/24
# 2. AZs serão geradas como:
#    - Main:   sa-east-1a até sa-east-1h
#    - Backup: us-east-1a até us-east-1h
# 3. Para customizar:
#    - Altere os índices ou sufixos conforme necessidade
