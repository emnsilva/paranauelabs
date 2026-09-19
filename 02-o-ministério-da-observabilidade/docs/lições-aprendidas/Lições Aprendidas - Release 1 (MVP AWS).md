Durante a adaptação da esteira de CI/CD para o GitHub Actions, enfrentei desafios de injeção de variáveis e instalação de binários.

## 1. O Token do TFC não era injetado na etapa de Plan (Required token could not be found)
**O que aconteceu:** O pipeline rodava o terraform init com sucesso, mas falhava no terraform plan dizendo que não encontrava o token de autenticação.<br>
**A causa:** No GitHub Actions, as variáveis de ambiente (env) estavam configuradas apenas dentro do step do init. Quando o step do plan rodava, o ambiente era limpo e o token se perdia.<br>
**A solução:** Movi o bloco env para o nível do Job inteiro. Assim, todos os steps (init, validate, plan, apply) herdam as variáveis de ambiente e o token não se perde no caminho.

## 2. GitHub Actions não injeta Secrets sem "Environments"
**O que aconteceu:** O pipeline não conseguia ler o Token do TFC configurado nas variáveis do repositório.<br>
**A causa:** Configurei as Secrets e Variables dentro de "Environments" (ex: dev, prod) no GitHub, mas o job não tinha a instrução environment: dev no código YAML.<br>
**A solução:** Adicionei a instrução environment: ${{ github.event.inputs.environment }} no job. Isso diz ao GitHub para carregar as secrets daquele ambiente específico antes de rodar os steps.

## 3. Conflito de Workspace com o Terraform Cloud (conflicts with TF_WORKSPACE)
**O que aconteceu:** O Terraform se recusava a rodar o plan, dizendo que havia um conflito de configuração de workspace.<br>
**A causa:** No arquivo versions.tf, deixei um nome de workspace fixo. Ao mesmo tempo, o pipeline injetava a variável TF_WORKSPACE.<br>
**A solução:** Removi o bloco workspaces do código HCL e passamos 100% do controle para o pipeline.