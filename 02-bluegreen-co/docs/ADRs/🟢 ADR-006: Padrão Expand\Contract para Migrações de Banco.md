# Número do ADR: 006

**Data:** 10-11-2026
**Responsável:** Equipe SRE/DevOps - Lab BlueGreen Co.
**Status:** 🟢 Aceito

## Contexto
O padrão Blue/Green exige que as versões v1 (Blue) e v2 (Green) coexistam no cluster por um período de tempo. Durante esse período, ambas as versões estarão atendendo tráfego. Se uma migração de banco for destrutiva (remover ou renomear colunas), a versão Blue quebrará enquanto a Green estiver no ar.

O problema central é: **como garantir que as migrações de banco de dados não quebrem a versão anterior, permitindo o rollback seguro em caso de falha?**

## Decisão
Adotar o padrão **Expand/Contract** para todas as migrações de banco de dados. Nesta release (R3), implementamos a fase *Expand* através de um `Job` do Kubernetes que executa um script SQL aditivo.

A implementação seguirá este desenho:
- **Fase Expand:** Toda alteração de schema é aditiva (novas colunas, novas tabelas). Nada é removido ou renomeado neste momento.
- **Fase Contract:** A remoção de colunas ou tabelas antigas só ocorre em um deploy futuro, após o switch definitivo para a versão Green.
- **Regra de ouro:** Nenhuma migração pode conter comandos `DROP COLUMN` ou `RENAME` no mesmo release em que a nova funcionalidade é introduzida.

## Justificativa
- **Zero downtime:** As duas versões funcionam simultaneamente com o mesmo schema.
- **Rollback seguro:** Se a Green falhar e precisarmos voltar para a Blue, o banco ainda tem todas as colunas que a Blue conhece.
- **Automação via GitOps:** O uso de um `Job` no Kubernetes permite que a migração seja versionada e executada de forma controlada antes de o app subir.

## Alternativas consideradas

### Alternativa 1: Ferramenta de Migração (Alembic/Flyway)
**Descrição:** Usar uma ferramenta complexa embutida na aplicação para rodar as migrações no boot.
**Por que foi descartada?** 
Para o escopo do laboratório, adicionar uma ferramenta de migração ao container da aplicação aumentaria o tamanho da imagem e a complexidade. Um `Job` nativo do Kubernetes cumpre o papel de forma isolada e mais simples.

### Alternativa 2: Migrações destrutivas com downtime
**Descrição:** Parar o tráfego, rodar a migração destrutiva e subir a nova versão.
**Por que foi descartada?** Contraria o objetivo central do laboratório, que é demonstrar zero downtime.

## Consequências

| POSITIVAS | NEGATIVAS/DESAFIOS |
|---|---|
| **Segurança no rollback:** O banco nunca perde dados que a versão anterior precisa. | **Processo mais lento:** Mudanças de schema exigem múltiplos deploys (expand e depois contract). |
| **Coexistência perfeita:** Blue e Green funcionam com o mesmo schema. | **Disciplina de time:** Exige que todos os desenvolvedores sigam a regra de ouro. |
| **Isolamento:** O `Job` roda independentemente do ciclo de vida da aplicação. | **Complexidade de testes:** É preciso testar a migração com as duas versões rodando simultaneamente. |

## Mitigações
- **Disciplina de time:** Documentar as regras no `runbook-operacao.md` e incluir checklist de revisão de PR.
- **Complexidade de testes:** O Experimento 4 da R5 será dedicado a validar o padrão expand/contract com as duas versões no ar.

## Registro de Mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por |
|---|---|---|---|---|
| 10-11-2026 | Primeira versão | Documentar a decisão de adotar o padrão Expand/Contract. | Garante que as migrações não quebrem a versão anterior durante a coexistência Blue/Green. | Emershow |