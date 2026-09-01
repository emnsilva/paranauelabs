A introdução do OpenTofu no GitHub Actions revelou diferenças importantes na forma como o fork lê o bloco cloud e como o GitHub lida com pipelines manuais.

## 1. OpenTofu exigiu o hostname no bloco Cloud (Hostname is required)
**O que aconteceu:** Ao rodar o tofu init, o OpenTofu devolvia o erro: failed to create backend alias to target "". The hostname is not in the correct format.
**A causa:** Diferente do Terraform original, que assume por padrão o hostname app.terraform.io quando não especificado, o OpenTofu é mais exigente e exige que o hostname seja declarado explicitamente no bloco cloud.
**A solução:** Adicionamos a linha hostname = "app.terraform.io" dentro do bloco cloud {} no arquivo versions.tf do OpenTofu.

## 2. Erro 403 da AWS ao assumir a Role (Not authorized to perform sts:AssumeRoleWithWebIdentity)
**O que aconteceu:** O tofu plan iniciava no Terraform Cloud, mas a AWS bloqueava a autenticação OIDC com erro 403.
**A causa:** Lá na AWS, a Trust Policy da Role de Dev estava configurada para aceitar apenas o workspace do Terraform (workspace:dev_aws_oidc). Como o OpenTofu usa um workspace diferente (dev_aws_tofu), a AWS bloqueava por segurança (Least Privilege).
**A solução:** Atualizamos a Trust Policy na AWS para aceitar o curinga workspace:dev_aws_*:run_phase:*. Isso permite que tanto o Terraform quanto o OpenTofu assumam a mesma Role, mantendo o isolamento dos states no TFC.

## 3. A diferença de UX: GitHub Actions não tem "Botão de Play" no meio do pipeline
**O que aconteceu:** No GitLab, nós usávamos when: manual para criar botões de Play (▶️) independentes para o Apply e o Destroy.
**A causa:** O GitHub Actions não possui um botão de pausa/play manual no meio de um workflow em execução. A aprovação manual (Gate) é vinculada ao Environment inteiro, o que fazia o pipeline pedir aprovação para cada etapa (validate, plan, apply) se estivessem em jobs separados.
**A solução:** Mudamos a estratégia. Em vez de botões no meio do pipeline, usamos workflow_dispatch com inputs (dropdowns) no início. O operador escolhe se quer fazer o "Deploy" ou o "Destroy" antes de apertar o botão de rodar. Para o "Deploy", as etapas (validate -> plan -> apply) rodam em sequência automática no mesmo job, evitando múltiplas telas de aprovação.

