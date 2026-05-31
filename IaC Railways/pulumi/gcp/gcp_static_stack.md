# Copie e cole esse modelo pra sua environment

values:
  regionA: "southamerica-east1"
  regionB: "us-east1"

  gcpKey:
  #Cole todo o conteúdo do arquivo .json da chave do Service Account
  # Exemplo:
  # {
  #   "type": "service_account",
  #   "project_id":     "ID do projeto no Google Cloud"
  #   "private_key_id": "ID da chave privada do Service Account"
  #   "private_key":    "Chave privada do Service Account"
  #   "client_email":   "Email do Service Account"
  #   "client_id":      "ID do Service Account"
  # }
  environmentVariables:
    GOOGLE_PROJECT: ${gcpKey.project_id}
    # O Pulumi ESC pega o bloco de chaves acima e injeta como uma string JSON válida
    GOOGLE_CREDENTIALS: ${gcpKey}
    CLOUDSDK_CORE_PROJECT: ${gcpKey.project_id}
  pulumiConfig:
    gcp:credentials: ${gcpKey}
    gcp:project: ${gcpKey.project_id}
    gcp:region: ${regionA}
    vars:regionPrimary: ${regionA}
    vars:regionSecondary: ${regionB}
