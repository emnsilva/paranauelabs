# subnets.tfvars
vpcs = {
  main = {
    region     = "sa-east-1"
    cidr_block = "10.0.0.0/16"
  }
  backup = {
    region     = "us-east-1"
    cidr_block = "10.1.0.0/16"
  }
}

subnet_colors    = ["red", "green", "blue", "yellow", "pink", "gold", "silver", "white"]
subnet_cidr_blocks = [
  "10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24", "10.0.4.0/24",
  "10.0.5.0/24", "10.0.6.0/24", "10.0.7.0/24", "10.0.8.0/24"
]
