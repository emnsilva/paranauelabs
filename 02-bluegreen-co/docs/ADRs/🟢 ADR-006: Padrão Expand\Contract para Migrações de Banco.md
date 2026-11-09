# Número do ADR: 006

**Data:** 09-11-2026
**Responsável:** Equipe SRE/DevOps - Lab BlueGreen Co.
**Status:** 🟢 Aceito

## Contexto

O padrão Blue/Green exige que as versões v1 (Blue) e v2 (Green) coexistam no cluster por um período de tempo. Durante esse período, ambas as versões estarão atendendo tráfego (Blue com 100%, Green com 0%, ou em fase de teste). Se uma migração de banco for destrutiva (remover ou renomear colunas), a versão Blue quebrará enquanto a Green estiver no ar.

O problema central é: **como garantir que as migrações de banco de dados não quebrem a versão anterior, permitindo o rollback seguro em caso de falha?**

## Decisão

Adotar o padrão **Expand/Contract** para todas as migrações de banco de dados, utilizando a ferramenta **Alembic** (nativa do ecossistema Python/SQLAlchemy).

A implementação seguirá este desenho:
- **Fase Expand:** Toda alteração de schema é aditiva (novas colunas, novas tabelas). Nada é removido ou renomeado neste momento.
- **Fase Contract:** A remoção de colunas ou tabelas antigas só ocorre em um deploy futuro, após o switch definitivo para a versão Green.
- **Regra de ouro:** Nenhuma migração pode conter comandos `DROP COLUMN` ou `RENAME` no mesmo release em que a nova funcionalidade é introduzida.

## Justificativa

- **Zero downtime:** As duas versões funcionam simultaneamente com o mesmo schema.
- **Rollback seguro:** Se a Green falhar e precisarmos voltar para a Blue, o banco ainda tem todas as colunas que a Blue conhece.
- **Integração com Python:** O Alembic permite escrever migrações em Python puro, facilitando a implementação de lógica condicional.

## Alternativas consideradas

### Alternativa 1: Flyway
**Descrição:** Ferramenta de migração baseada em SQL, amplamente usada no ecossistema Java.
**Por que foi descartada?**
- Exige uma JVM (Java Virtual Machine) para rodar, adicionando overhead desnecessário ao lab, que é baseado em Python.

### Alternativa 2: SQL puro sem ferramenta de migração
**Descrição:** Rodar scripts SQL manualmente ou via `kubectl exec`.
**Por que foi descartada?**
- Sem controle de versão, sem rastreabilidade e sem garantia de ordem de execução.

### Alternativa 3: Migrações destrutivas com downtime
**Descrição:** Parar o tráfego, rodar a migração destrutiva e subir a nova versão.
**Por que foi descartada?**
- Contraria o objetivo central do laboratório, que é demonstrar zero downtime.

## Consequências

| POSITIVAS | NEGATIVAS/DESAFIOS |
|---|---|
| **Segurança no rollback:** O banco nunca perde dados que a versão anterior precisa. | **Processo mais lento:** Mudanças de schema exigem múltiplos deploys (expand e depois contract). |
| **Coexistência perfeita:** Blue e Green funcionam com o mesmo schema. | **Disciplina de time:** Exige que todos os desenvolvedores sigam a regra de ouro. |
| **Ferramenta nativa:** O Alembic integra-se perfeitamente com o SQLAlchemy da aplicação Flask. | **Complexidade de testes:** É preciso testar a migração com as duas versões rodando simultaneamente. |

## Mitigações

- **Disciplina de time:** Documentar as regras no `runbook-operacao.md` e incluir checklist de revisão de PR para migrações.
- **Complexidade de testes:** O Experimento 4 da R5 será dedicado a validar o padrão expand/contract com as duas versões no ar.
- **Processo mais lento:** Aceitar como trade-off necessário para o zero downtime. Para funcionalidades que exigem remoção, planejar dois releases separados.

## Registro de Mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por |
|---|---|---|---|---|
| 09-11-2026 | Primeira versão | Documentar a decisão de adotar o padrão Expand/Contract, sustentada pelo spike do card 3.5. | Garante que as migrações não quebrem a versão anterior durante a coexistência Blue/Green. | Emershow |