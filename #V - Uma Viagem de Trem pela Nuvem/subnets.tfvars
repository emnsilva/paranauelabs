vpc_data = {
  main = {
    vpc_id    = "vpc-123main"   # Substitua pelo ID real
    region    = "sa-east-1",
    cidr_base = "10.0"
  },
  backup = {
    vpc_id    = "vpc-456backup" # Substitua pelo ID real
    region    = "us-east-1",
    cidr_base = "10.1"
  }
}

# Modelo padrão para 8 subnets (customizável)
subnets_public = [
  { az_suffix = "a", cidr_index = 1 },
  { az_suffix = "b", cidr_index = 2 },
  { az_suffix = "c", cidr_index = 3 },
  { az_suffix = "d", cidr_index = 4 },
  { az_suffix = "e", cidr_index = 5 },
  { az_suffix = "f", cidr_index = 6 },
  { az_suffix = "g", cidr_index = 7 },
  { az_suffix = "h", cidr_index = 8 }
]
