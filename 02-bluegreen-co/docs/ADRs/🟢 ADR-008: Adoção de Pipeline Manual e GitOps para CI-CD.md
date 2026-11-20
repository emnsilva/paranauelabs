**Data:** 20-11-2026
**Responsável:** Equipe SRE/DevOps - Lab BlueGreen Co.
**Status:** 🟢 Aceito

## Contexto
O laboratório precisava de uma esteira de CI/CD para construir imagens, escanear vulnerabilidades e atualizar a versão no cluster. O modelo tradicional (CI dando deploy direto via `kubectl`) expõe credenciais do cluster para o GitHub. O modelo GitOps (CI atualiza o Git e o Argo CD faz o deploy) é mais seguro. Além disso, por ser um laboratório de estudos, não queríamos que cada commit disparasse um build e um deploy acidental, consumindo recursos e minutos gratuitos.

O problema central é: **como automatizar o build e o deploy sem expor o cluster e mantendo o controle total sobre quando um deploy deve ocorrer?**

## Decisão
Adotar um fluxo de CI/CD baseado em **GitOps com acionamento manual**. O GitHub Actions será disparado via `workflow_dispatch` (botão "Run workflow"). Ele vai construir a imagem, escanear com Trivy e, se tudo passar, atualizar a tag no arquivo `deployment.yaml` do GitOps. O Argo CD, ao detectar a mudança no Git, fará o deploy da nova versão.

A implementação seguirá este desenho:
- **Acionamento Manual:** O workflow terá `on: workflow_dispatch`.
- **Atualização GitOps:** Uso da ferramenta `yq` para editar a tag no `deployment.yaml` e `GITHUB_TOKEN` para commit e push.
- **Separação de Responsabilidades:** O GitHub Actions constrói e altera o Git. O Argo CD aplica no cluster.

## Justificativa
- **Controle Total:** O acionamento manual garante que o operador saiba exatamente quando uma nova versão está sendo promovida, simulando o processo de aprovação de um ambiente de produção.
- **Segurança:** O pipeline de CI não tem acesso ao cluster, apenas ao repositório Git. O Argo CD (que está dentro do cluster) puxa as mudanças.
- **Economia:** Como o lab é desligado frequentemente, builds automáticos a cada push seriam desperdiçados.

## Alternativas consideradas

### Alternativa 1: Deploy direto via CI (Push-based)
**Descrição:** O GitHub Actions se conecta ao cluster k3s e aplica os manifests.
**Por que foi descartada?**
- Exigiria expor o `kubeconfig` do cluster para o GitHub Actions, o que é uma falha de segurança grave.

### Alternativa 2: CI Totalmente Automático (Pull-based via Webhook)
**Descrição:** Todo push na `main` dispara o build e a atualização da tag.
**Por que foi descartada?**
- Como o lab é desmontado com frequência e usado para testes, deploys automáticos acidentais consumiriam minutos do GitHub Actions e poluiriam o cluster.

## Consequências

| POSITIVAS | NEGATIVAS/DESAFIOS |
|---|---|
| **Controle absoluto:** Nenhum deploy ocorre sem ação humana. | **Exige ação manual:** É preciso clicar no botão para cada deploy. |
| **Seguro por design:** O cluster nunca é exposto a chaves externas. | **Dependência do Token:** A pipeline pode falhar se o `GITHUB_TOKEN` tiver problemas de permissão. |
| **Auditável:** O histórico do Git reflete exatamente o que foi promovido. | — |

## Mitigações
- **Teste do yq:** O script do GitHub Actions será testado isoladamente para garantir que a edição do YAML não corrompa o arquivo.
- **Documentação:** O processo manual estará documentado no Runbook.

## Registro de Mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por |
|---|---|---|---|---|
| 20-11-2026 | Primeira versão | Documentar a decisão do pipeline manual e GitOps. | Maior segurança e controle de custos para o lab. | Emershow |