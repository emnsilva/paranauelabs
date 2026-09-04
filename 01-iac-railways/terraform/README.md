## Terraform - IaC Railways
Este diretório contém o código de infraestrutura declarativo (HCL) utilizando o OpenTofu (fork open-source do Terraform) para provisionamento do baseline nas 4 clouds (AWS, Azure, GCP e Oracle).

---

## 📂 Estrutura
Cada cloud possui seu próprio diretório isolado contendo os arquivos .tf:
- aws/ - Provisionamento na Amazon Web Services
- azure/ - Provisionamento na Microsoft Azure
- gcp/ - Provisionamento na Google Cloud Platform
- oci/ - Provisionamento na Oracle Cloud Infrastructure

---

## ⚙️ Execução Local
Embora a esteira de CI/CD (GitHub Actions/Jenkins + Terraform Cloud) seja a responsável oficial pelos deploys, você pode executar este código localmente para testes.
1. Renomeie o terraform.tfvars.example para terraform.tfvars e ajuste os valores.
2. Autentique-se na cloud desejada via CLI (ex: aws sso login ou az login).
3. Inicialize o backend (requer token do Terraform Cloud configurado):
```
terraform init
```
4. Valide o plano de execução:
```
terraform plan
```

---

## 🔗 Integração com CI/CD
O pipeline que orquestra este código no GitHub Actions está localizado em `../../.github/workflows/tfc-master-pipeline.yml`. O estado remoto (`tfstate`) continua sendo gerenciado pelo Terraform Cloud no modo CLI-driven, garantindo o state lock e a integridade da infraestrutura.
