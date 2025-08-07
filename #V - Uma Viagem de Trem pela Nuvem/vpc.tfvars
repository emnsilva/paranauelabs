# tf.tfvars: Atribui valores específicos às variáveis. São informações sensíveis que não podem ser expostas.
# Sobrescreva os valores padrão aqui para ambientes específicos
vpcs = {
  main = {  # VPC main
    region     = "sa-east-1"    # Sua região principal
    cidr_block = "10.0.0.0/16"  # Faixa de IPs
  }
  
  backup = {   # VPC backup
    region     = "us-east-1"    # Sua região de backup
    cidr_block = "10.1.0.0/16"  # Faixa de IPs. Não deve sobrepor com a main
  }
  
  # EXEMPLO: Adicione novas regiões conforme necessário
  # europe = {
  #   region     = "eu-west-1"
  #   cidr_block = "10.2.0.0/16"
  # }
}
