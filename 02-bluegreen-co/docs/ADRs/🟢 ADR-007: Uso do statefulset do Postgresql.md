**Número do ADR:** 007
**Data:** 10-11-2026
**Responsável:** Equipe SRE/DevOps - Lab BlueGreen Co.
**Status:** 🟢 Aceito

## Contexto
Este ADR substitui o ADR-005. A tentativa de usar o CloudNativePG (CNPG) como operador de banco de dados no cluster k3s (Alpine) resultou em falhas contínuas de inicialização (`CrashLoopBackOff`). O CNPG depende de webhooks de admissão complexos e certificados que entram em conflito com as restrições de rede e memória do laboratório. 

O problema central é: **como prover um PostgreSQL estável e com persistência de dados no k3s, sem o overhead de um operador feito para grandes nuvens?**

## Decisão
Adotar um **StatefulSet nativo do Kubernetes** rodando a imagem oficial `postgres:16-alpine`, acompanhado de um `Service` (ClusterIP), um `PersistentVolumeClaim` (PVC) e um `Secret` para as credenciais.

A implementação seguirá este desenho:
- **StatefulSet:** Executa 1 réplica do PostgreSQL com limites de recursos bem definidos.
- **Persistência:** Uso da `StorageClass` `local-path` para garantir que os dados sobrevivam a reinicializações do pod.
- **Gestão de Schema:** Um `Job` do Kubernetes é executado logo após a criação do banco para aplicar as migrações SQL (padrão expand/contract).
- **Sem Webhooks:** Elimina a dependência de certificados e regras de admissão complexas.

## Justificativa
- **Estabilidade:** O StatefulSet não possui webhooks ou validadores que possam falhar. O pod sobe em segundos e fica `Running` imediatamente.
- **Leveza:** Consome apenas a memória necessária para o processo do Postgres, sem controladores extras.
- **Persistência Garantida:** Mantém a integridade dos dados entre os deploys (essencial para o teste Blue/Green).
- **Simplicidade:** Fácil de depurar e gerenciar via GitOps.

## Alternativas consideradas

### Alternativa 1: Continuar com CloudNativePG
**Descrição:** Insistir na configuração do CNPG desabilitando webhooks e aumentando cotas.
**Por que foi descartada?**
- Perda de tempo excessiva. O foco do lab é Blue/Green, não a manutenção de operadores complexos. O ambiente k3s/Alpine é hostil a esse tipo de operador.

### Alternativa 2: Bitnami PostgreSQL (Helm)
**Descrição:** Usar o Helm chart da Bitnami para criar o StatefulSet.
**Por que foi descartada?**
- Apesar de funcional, o chart traz várias configurações padrão (métricas, backups) que não precisamos. Um StatefulSet puro e limpo é mais fácil de explicar e auditar.

## Consequências

| POSITIVAS | NEGATIVAS/DESAFIOS |
|---|---|
| **Subida instantânea:** O banco fica disponível rapidamente. | **Sem HA automática:** Não temos failover gerenciado (aceitável no lab). |
| **Controle total:** O manifesto YAML faz exatamente o que está escrito, sem "mágica" de operador. | **Backups manuais:** Se quiséssemos backups no lab, teríamos que criar CronJobs. |
| **Alinhado ao escopo:** Foco no GitOps e no Blue/Green. | — |

## Mitigações
- **Persistência:** O PVC garante que os dados não são perdidos se o pod reiniciar.
- **Migrações:** O `Job` de migração garante que o schema esteja sempre atualizado antes de o app subir.

## Registro de Mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por |
|---|---|---|---|---|
| 10-11-2026 | Primeira versão | Documentar a migração para StatefulSet após a falha do CNPG. | Garante um banco estável e leve para o laboratório. | Emershow |