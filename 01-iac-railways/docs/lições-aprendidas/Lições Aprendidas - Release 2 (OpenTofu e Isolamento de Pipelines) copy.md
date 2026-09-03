A expansão da matriz para Azure, GCP e Oracle, culminando na criação dos Pipelines Mestres dinâmicos no GitHub Actions, revelou aprendizados profundos sobre limitações de nuvem e arquitetura de CI/CD.

## 1. O Pragmatismo do Pipeline Mestre (UX e DRY)
**O que aconteceu:** Tínhamos 8 arquivos .yml separados (tfc-aws, tofu-azure, etc), o que violava o princípio DRY e poluía a aba de Actions.<br>
**A causa:** A refactoração inicial tentou usar variáveis indiretas do Bash (${!VAR_NAME}) dentro de um único pipeline unificado, o que causou falhas de leitura de variáveis no shell do GitHub Actions<br>
**A solução:** Dividimos em dois Pipelines Mestres (tfc-master-pipeline.yml e tofu-master-pipeline.yml). Usando os inputs (dropdowns) nativos do GitHub Actions e condicionais simples de Bash (if [ cloud == aws ]), montamos o working-directory e o TF_WORKSPACE dinamicamente. Isso reduziu o código de CI/CD pela metade e melhorou a UX de quem opera a esteira.

## 2. O Azure Entra ID e a Rigidez do OIDC
**O que aconteceu:** O terraform plan falhava no Azure com erro 401 invalid_client (AADSTS700213)<br>
**A causa:** Diferente da AWS e do GCP, o Azure NÃO aceita curingas (*) no final da string de Subject do Federated Credential. Ele exige a string EXATA.<br>
**A solução:** Foi necessário criar 3 credenciais federadas separadas para cada workspace (uma para run_phase:plan, uma para apply e uma para destroy). Isso aumentou o trabalho de setup, mas garante um isolamento de fase rigoroso no Azure.

## 3. O Compartmentalizaço da Oracle (OCI) e a Ausência de OIDC Nativo
**O que aconteceu:** TFC e GitHub Actions não possuem suporte nativo a OIDC para a Oracle Cloud (OCI) de forma tão transparente quanto as outras clouds. A configuração manual de Identity Domains na OCI provou-se excessivamente complexa e propensa a erros.<br>
**A solução:** Decisão arquitetual pragmática. Para a Oracle, mantivemos a autenticação via API Key (injetada via Variable Set do TFC como TF_VAR_private_key, etc). Isso manteve a esteira funcional e automatizada, reconhecendo que a OCI tem uma maturidade de integração diferente das outras clouds neste aspecto.

## 4. A Exigência do OpenTofu por hostname
**O que aconteceu:** O tofu init falhava com o erro failed to create backend alias to target "". The hostname is not in the correct format.<br>
**A causa:**  Diferente do Terraform original, que assume por padrão o hostname app.terraform.io, o OpenTofu exige que ele seja declarado explicitamente no bloco cloud.<br>
**A solução:** Adicionamos a linha hostname = "app.terraform.io" no bloco cloud {} de todos os arquivos versions.tf do OpenTofu.

