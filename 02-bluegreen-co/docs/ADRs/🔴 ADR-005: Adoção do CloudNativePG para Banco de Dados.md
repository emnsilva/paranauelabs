**Número do ADR:** 005
**Data:** 09-11-2026
**Responsável:** Equipe SRE/DevOps - Lab BlueGreen Co.
**Status:** 🔴 Substituído pelo ADR-007

## Contexto
O laboratório precisa de um banco de dados PostgreSQL real para a aplicação `bgapp`. O ambiente é restrito: o cluster k3s roda em 3 VMs, com workers de 3 GB de RAM cada. O banco precisa ser resiliente o suficiente para simular um ambiente de produção, mas leve o suficiente para não estourar as cotas de recursos do laboratório.

## Decisão
*[Histórico]* Adotar o **CloudNativePG (CNPG)** como operador de banco de dados, provisionando uma instância única do PostgreSQL. 

## Justificativa
- **Padrão de mercado:** O CloudNativePG é um projeto CNCF, amplamente utilizado em produção.
- **Inteligência operacional:** O CNPG gerencia backups, atualizações e recriação automática de pods.
- **Integração com o ecossistema:** O CNPG se integra nativamente ao Argo CD (via CRD `Cluster`).

## Alternativas consideradas

### Alternativa 1: Bitnami PostgreSQL (Helm Chart)
**Descrição:** Instalar o PostgreSQL via chart Helm da Bitnami, usando um `StatefulSet`.<br>

**Por que foi descartada?**
- É mais leve que o operador, mas não possui inteligência de failover ou backups automáticos.
- Para o portfólio, usar um operador Kubernetes (CRD) agrega mais valor técnico do que um chart genérico.

### Alternativa 2: PostgreSQL em Pod isolado com PVC
**Descrição:** Criar um `Deployment` simples com um PVC para o banco.<br>

**Por que foi descartada?**
- Não é resiliente (se o pod morrer, o banco fica indisponível até o Kubernetes recriá-lo).
- Não reflete um ambiente de produção minimamente realista.

## Consequências

| POSITIVAS | NEGATIVAS/DESAFIOS |
|---|---|
| **Padrão Operator:** Demonstra domínio de CRDs e gestão declarativa de bancos de dados. | **Footprint de memória:** O operador consome cerca de 100 MB adicionais, o que é significativo no lab. |
| **Auto-healing:** O CNPG recria a instância automaticamente em caso de falha. | **Curva de aprendizado:** Exige entender o CRD `Cluster` do CNPG e seus parâmetros de configuração. |
| **Backup preparado:** A estrutura está pronta para habilitar backups point-in-time no futuro. | **Restrição de HA:** Não é possível testar failover real com apenas 1 instância. |

## Registro de Mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por |
|---|---|---|---|---|
| 09-11-2026 | Primeira versão | Documentar a decisão de adotar CloudNativePG. | Prover banco PostgreSQL gerenciado. | Emershow |
| 10-11-2026 | Status alterado para Substituído | O operador apresentou falhas críticas no k3s (CrashLoopBackOff). | Decisão revertida em favor do ADR-008 (StatefulSet). | Emershow |