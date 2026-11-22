**Data:** 22-11-2026
**Release:** R4 - `v1.0.0-beta.2`
**Foco:** Automatizar o build, scan de segurança e atualização do GitOps.

## 1. Contexto da R4
O objetivo era tirar o deploy manual e criar uma pipeline de CI que construísse a imagem, escaneasse vulnerabilidades e atualizasse o repositório Git. O grande desafio era fazer isso sem expor o cluster e mantendo o acionamento manual.

## 2. O que funcionou
- **O acionamento manual:** O `workflow_dispatch` com input de tag deu controle total sobre os deploys.
- **O Trivy:** O scan de segurança funcionou perfeitamente. Ele bloqueou o deploy por 16 vulnerabilidades HIGH na biblioteca `krb5-libs`, e conseguimos corrigir atualizando o Dockerfile.
- **A atualização do GitOps:** O `yq` fez a mágica de alterar a tag no YAML, e o `GITHUB_TOKEN` fez o commit com sucesso.

## 3. O que não funcionou (ou deu trabalho)
- **A action do `yq`:** A action `mikefarah/yq-action` foi deletada do GitHub. Foi necessário substituir por um download direto do binário.
- **O erro de "divergent branches":** O `git pull` deu conflito porque o robô do GitHub Actions e o desenvolvedor commitaram ao mesmo tempo. Solução: usar `git pull --rebase`.
- **Falso Positivo no Trivy:** A primeira tentativa de corrigir a vulnerabilidade (apenas com `apk upgrade`) não foi suficiente. Foi preciso forçar a atualização do pacote `krb5` especificamente.

## 4. O que aprendemos
- **GitOps exige disciplina:** Toda vez que a pipeline rodar, o código local precisa ser atualizado (`git pull`). A esteira é a "fonte da verdade".
- **Segurança de imagem é real:** O Trivy mostrou que a imagem base `Alpine 3.24.4` tinha falhas no `krb5`. Forçar o upgrade dos pacotes é essencial para um portfólio.
- **Manual não significa ultrapassado:** Para um lab, o acionamento manual é muito melhor do que deploys automáticos que consomem recursos sem necessidade.

## 5. O que faremos diferente na R5 (Blue/Green)
- **Foco no Argo Rollouts:** Vamos substituir o `Deployment` padrão pelo `Rollout` para provar o padrão Blue/Green com análise de métricas.
- **Testes de zero downtime:** O teste de carga (`k6`) será a estrela da R5.