Número do ADR: 004<br>
Data: 18-09-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto O Ministério da Observabilidade<br>
Status: 🔴 Substituído por ADR-009 (a ferramenta mudou — Terraform saiu, k3s + Helm + Makefile entraram; o princípio permanece intocado)

## Contexto
Um laboratório que só funciona na máquina de quem o montou não prova nada. Montagem manual significa passos esquecidos, diferença silenciosa entre o que está documentado e o que está rodando (drift), e impossibilidade prática de recomeçar do zero — o que enfraquece qualquer conclusão, já que o ambiente nunca é exatamente o mesmo duas vezes.

## Decisão
Tudo que sobe no laboratório é criado por código versionado no repositório (na versão original: Terraform/Helm). O lab inteiro deve poder ser destruído e reconstruído do zero por um único comando, em menos de duas horas — requisito que virou o teste de reprodução (futuro make demo).<br>

## Justificativa
1. **Credibilidade:** Conclusões de um ambiente refazível valem mais que as de um ambiente artesanal.
2. **Recuperação rápida:** Qualquer desastre tem resposta de horas, não de fins de semana.
3. **Detecção de drift:** Se alguém alterou manualmente, a divergência aparece na reconstrução.

## Alternativas consideradas
**Alternativa 1: Montagem manual (console/terminal, sem código)**<br>
Descrição: Montar toda a infraestrutura manualmente via IDE/terminal.<br>

**Por que foi descartada?** <br>
Não é refazível; passos vivem na memória do executor; drift invisível.<br>

**Alternativa 2: Automação parcial (scripts soltos)**<br>
Descrição: Subir a infraestrutura usando scripts.<br>

**Por que foi descartada?**<br>
Ordem de execução vira conhecimento tribal; metade do lab fica reproduzível, metade não.<br>

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Ambiente auditável:** O repositório é a descrição verdadeira do lab. | **Investimento inicial:** escrever tudo como código custa tempo antes de ver qualquer dashboard. |
| **Reconstrução em horas:** O teste de < 2h vira critério de release. | **Manutenção contínua:** mudanças precisam passar pelo código, nunca manualmente. |
| **Segurança Centralizada:** As Roles de OIDC das clouds ficam configuradas apenas no TFC, reduzindo exposição no repositório de código. | **Overhead de Execução:** O modo CLI-driven adiciona um pequeno overhead de rede ao enviar o código do GitHub para o TFC antes de rodar o plan/apply. |
| **Paridade OpenTofu:** A estrutura suporta o OpenTofu sem mudanças arquiteturais, apenas criando novos workspaces. | **Gestão de Tokens:** É necessário rotacionar e gerenciar o API Token do TFC nas variáveis do GitLab de forma segura. |

## Mitigações
- Teste de reprodução como requisito de aceite da Release 1.
- Pipeline de CI valida a sintaxe de tudo que é código.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 18-09-2026 | Primeira versão  | Transcrição da decisão de planejamento | Estabelece a regra "tudo como código" | Emershow |
| 18-09-2026 | Substituído por ADR-009  | VMs próprias como alvo + Terraform já demonstrado no lab 01 | A ferramenta muda; o princípio e o teste de < 2h permanecem | Emershow |