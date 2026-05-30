aws:
    login:
      fn::open::aws-login:
        static:
          accessKeyId: "A chave do usuário IAM"
          secretAccessKey: "Chave secreta do usuário IAM"

  environmentVariables:
    # Variáveis globais que qualquer CLI ou SDK da AWS lê por padrão
    AWS_ACCESS_KEY_ID: ${aws.login.accessKeyId}
    AWS_SECRET_ACCESS_KEY: ${aws.login.secretAccessKey}
    AWS_DEFAULT_REGION: ${regionDefault}

  pulumiConfig:
    # Configuração oficial do provedor AWS do Pulumi (válida para todas as linguagens)
    aws:region: ${regionDefault}