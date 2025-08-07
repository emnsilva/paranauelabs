vpcs = {
  main = { region = "sa-east-1", cidr_base = "10.0" },
  backup  = { region = "us-east-1", cidr_base = "10.1" }
}

# O template é reutilizado para ambas as VPCs!
subnet_template = [
  { az_suffix = "a", cidr_index = 1 },
  { az_suffix = "b", cidr_index = 2 },
  { az_suffix = "c", cidr_index = 3 },
  { az_suffix = "d", cidr_index = 4 },
  { az_suffix = "e", cidr_index = 5 },
  { az_suffix = "f", cidr_index = 6 },
  { az_suffix = "g", cidr_index = 7 },
  { az_suffix = "h", cidr_index = 8 },
]
