# Número do ADR: 005

**Data:** 09-11-2026
**Responsável:** Equipe SRE/DevOps - Lab BlueGreen Co.
**Status:** 🟢 Aceito

## Contexto
O laboratório precisa de um banco de dados PostgreSQL real para a aplicação `bgapp`, que será usada nos testes de Blue/Green. O ambiente é restrito: o cluster k3s roda em 3 VMs, com workers de 3 GB de RAM cada. O banco precisa ser resiliente o suficiente para simular um ambiente de produção, mas leve o suficiente para não estourar as cotas de recursos do laboratório (`ResourceQuota` de 2Gi no namespace `bluegreen`).

O problema central é: **como prover um PostgreSQL gerenciado e resiliente dentro do k3s, sem comprometer a estabilidade do cluster por falta de memória?**

## Decisão
Adotar o **CloudNativePG (CNPG)** como operador de banco de dados, provisionando uma instância única do PostgreSQL (sem réplica de alta disponibilidade, devido à restrição de hardware). O armazenamento será provido pela `StorageClass` local do k3s (`local-path`).

A implementação seguirá este desenho:
- **Instância única:** O recurso `Cluster` do CNPG será configurado com `instances: 1` para economizar RAM.
- **Limites de recursos:** O container do Postgres terá `requests` de 100Mi e `limits` de 256Mi.
- **Gestão de credenciais:** Um `Secret` do Kubernetes armazenará as credenciais, consumidas pela aplicação via `envFrom`.

## Justificativa
- **Padrão de mercado:** O CloudNativePG é um projeto CNCF, amplamente utilizado em produção. Demonstra domínio do padrão *Operator*, que é um diferencial sênior no portfólio.
- **Inteligência operacional:** Mesmo com uma instância única, o CNPG gerencia backups, atualizações e recriação automática de pods (auto-healing), o que um simples `StatefulSet` não faz.
- **Integração com o ecossistema:** O CNPG se integra nativamente ao Argo CD (via CRD `Cluster`), mantendo a filosofia GitOps.

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

## Mitigações

- **Consumo de memória:** Configuração rigorosa de `requests` e `limits` (100Mi/256Mi) e desabilitação de métricas extras do CNPG.
- **Restrição de HA:** Documentar no README que o lab usa instância única por restrição de hardware, e que em produção seriam necessárias 3 instâncias (1 primary + 2 standbys).

## Registro de Mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por |
|---|---|---|---|---|
| 09-11-2026 | Primeira versão | Documentar a decisão de adotar CloudNativePG, sustentada pelo spike do card 3.3. | Prover banco PostgreSQL gerenciado e resiliente dentro da cota de memória do lab. | Emershow |