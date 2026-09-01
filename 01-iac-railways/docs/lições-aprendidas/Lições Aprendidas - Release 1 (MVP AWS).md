Durante a adaptação da esteira de CI/CD do GitLab para o GitHub Actions, enfrentamos desafios particulares de sintaxe e injeção de variáveis. Aqui está o registro desses aprendizados.

## 1. O Token do TFC não era injetado na etapa de Plan (Required token could not be found)
**O que aconteceu:** O pipeline rodava o terraform init com sucesso, mas falhava no terraform plan dizendo que não encontrava o token de autenticação.<br>
**A causa:** No GitHub Actions, as variáveis de ambiente (env) estavam configuradas apenas dentro do step do init. Quando o step do plan rodava, o ambiente era limpo e o token se perdia.<br>
**A solução:** Movemos o bloco env para o nível do Job inteiro. Assim, todos os steps (init, validate, plan, apply) herdam as variáveis de ambiente e o token não se perde no caminho.

## 2. A versão 1.5.8 do Terraform não existe (No matching version found)
**O que aconteceu:** O pipeline falhava na etapa de instalação do binário do Terraform.<br>
**A causa:** A HashiCorp pulou a versão 1.5.8 no registro público! Eles lançaram a 1.5.7 e depois foram direto para a 1.6.0.<br>
**A solução:** Atualizamos a versão no hashicorp/setup-terraform para uma versão válida (1.6.0, e posteriormente para a 1.16.0 conforme validado localmente).

## 3. GitHub Actions não injeta Secrets sem "Environments"
**O que aconteceu:** O pipeline não conseguia ler o Token do TFC configurado nas variáveis do repositório.<br>
**A causa:** Nós configuramos as Secrets e Variables dentro de "Environments" (ex: dev, prod) no GitHub, mas o job não tinha a instrução environment: dev no código YAML.<br>
**A solução:** Adicionamos a instrução environment: ${{ github.event.inputs.environment }} no job. Isso diz ao GitHub para carregar as secrets daquele ambiente específico antes de rodar os steps.