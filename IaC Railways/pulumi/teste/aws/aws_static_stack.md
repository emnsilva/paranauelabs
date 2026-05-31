# Copie e cole esse modelo pra sua environment
# Substitua accessKeyId e secretAccessKey pelas suas chaves

values:
  regionA: "sa-east-1"
  regionB: "us-east-1"

  aws:
    login:
      fn::open::aws-login:
        static:
          accessKeyId: "A chave do usuário IAM"
          secretAccessKey: "Chave secreta do usuário IAM"

  environmentVariables:
    AWS_ACCESS_KEY_ID: ${aws.login.accessKeyId}
    AWS_SECRET_ACCESS_KEY: ${aws.login.secretAccessKey}

  pulumiConfig:
    # Usamos o nome do seu projeto para expor as duas variáveis de forma abrangente
    seu_projeto:regionPrimary: ${regionA}
    seu_projeto:regionSecondary: ${regionB}