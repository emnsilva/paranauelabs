# Número do ADR: 003
**Data:** 06-11-2026
**Responsável:** Equipe SRE/DevOps - Lab BlueGreen Co.
**Status:** 🟢 Aceito

## Contexto
O laboratório é composto por múltiplos componentes (Ingress, Cert-Manager, futuramente Observabilidade e a própria aplicação). A gestão manual desses recursos via CLI (`kubectl apply` ou `helm install`) apresenta sérios riscos: falta de auditoria (quem alterou o quê e quando), divergência de estado (drift) e dificuldade de reprodução. Em um cenário de portfólio, é fundamental demonstrar que as mudanças são governadas e rastreáveis.

O problema central é: **como garantir que o cluster reflita exatamente o que está versionado no repositório, corrigindo desvios automaticamente e sem intervenção humana?**

## Decisão
Adotar o **Argo CD** como a ferramenta de GitOps e implantar o padrão **App-of-Apps**. O estado desejado do cluster é declarado em manifests no GitHub. O Argo CD monitora o repositório e reconcilia o cluster. 

A implementação seguirá este desenho:
- **App-of-Apps:** A aplicação `root-app` aponta para a pasta `cluster/apps/children/`. Qualquer novo arquivo nesta pasta se torna uma nova aplicação gerenciada automaticamente.
- **Self-Healing e Pruning:** `selfHeal: true` garante que alterações manuais no cluster sejam revertidas para o estado do Git. `prune: true` garante que recursos removidos do Git sejam deletados do cluster.

## Justificativa
- **Auditoria Total:** O Git funciona como log de auditoria imutável.
- **Auto-recuperação:** O cluster se cura automaticamente de intervenções manuais.
- **Facilidade de Expansão:** Adicionar o Prometheus, por exemplo, exige apenas um novo arquivo YAML na pasta `children/`, sem rodar comandos no cluster.
- **Interface Visual:** O Argo CD oferece uma UI que visualiza a árvore de dependências, algo valioso para a apresentação do portfólio.

## Alternativas consideradas

### Alternativa 1: Flux CD
**Descrição:** Outra ferramenta GitOps amplamente utilizada (parte do ecossistema CNCF).
**Por que foi descartada?**
- O Argo CD possui uma interface gráfica nativa muito superior, o que facilita imensamente a demonstração do GitOps em um portfólio.
- A integração com o Argo Rollouts (ferramenta escolhida para o blue/green) é natural, pois ambas pertencem ao mesmo ecossistema.

### Alternativa 2: Scripts de CI/CD tradicionais (`kubectl apply` no pipeline)
**Descrição:** O GitHub Actions se conectaria ao cluster e aplicaria os manifests a cada push.
**Por que foi descartada?**
- Não possui reconciliação contínua. Se alguém deletar um pod manualmente, o pipeline não recria.
- Exige a exposição do cluster (ou de um agente) para o GitHub Actions, o que adiciona complexidade de segurança desnecessária ao lab.

## Consequências

| POSITIVAS | NEGATIVAS/DESAFIOS |
|---|---|
| **Auditoria completa:** Todo estado no cluster tem um commit correspondente. | **Overhead de recursos:** O Argo CD consome cerca de 1 GB de RAM do cluster, o que é significativo para o lab. |
| **Auto-recuperação:** O cluster se mantém no estado desejado mesmo com falhas humanas. | **Curva de aprendizado:** Exige familiaridade com CRDs (`Application`), sync policies e troubleshooting de divergência (OutOfSync). |
| **Reprodutibilidade:** O cluster pode ser recriado inteiramente a partir do Git. | **Complexidade inicial:** Configurar o App-of-Apps exige o entendimento de como as aplicações filhas são descobertas. |

## Mitigações
- **Consumo de Memória:** Desabilitar componentes não utilizados do Argo CD (Dex Server, Notifications) e ajustar os limites de `requests/limits` para caber nas `ResourceQuotas` do cluster.
- **Curva de aprendizado:** Documentar o fluxo no `runbook-operacao.md` e criar o App-of-Apps com estrutura de pastas clara para facilitar a manutenção.

## Registro de Mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por |
|---|---|---|---|---|
| 06-11-2026 | Primeira versão | Documentar a decisão de adotar GitOps e o App-of-Apps com Argo CD. | Centraliza o estado no Git, melhora auditoria e facilita a expansão do lab. | Emershow |