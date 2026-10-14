## Matriz de Decisão de Stack v1
Regra de ouro: pesos definidos ANTES das medições. Alteração após oinício das medições exige nova versão deste documento + ADR justificando.

## 1. Contexto e pergunta de decisão
O paranauelabs precisa de um padrão para as próximas APIs da casa. Hoje, aescolha entre Node e Python — e entre MongoDB e PostgreSQL — acontece porpreferência ou hype, sem evidência medida no nosso contexto. Este lab(Onde no Banco de Dados Está Carmen Sandiego?) implementará a MESMA APInas duas stacks, em condições idênticas, e preencherá esta matriz comdados reais. A matriz define ANTES como os dados serão julgados.

A pergunta tem duas respostas, e a matriz as produz ambas:

1. Qual stack vence? (a recomendação formal)
2. Quando cada paradigma brilha? (o mapa de paradigma — sobrevivemesmo a empate técnico, e orienta escolhas futuras caso a caso)

## 2. Critérios, pesos e métodos de medição

| Critério | Peso | O que mede | Como é medido | Quando | Fonte |
| :--- | :--- | :--- | :--- | :--- | :--- |
| Performance (p95) | 25 | latência das operações principais por endpoint | medição local, carga leve definida, após aquecimento (cold start excluído) — Outcome 4 | R5 | benchmark local |
| Tempo de desenvolvimento | 25 | esforço real de construir e manter na stack |	registro de horas por stack (inclui custo de aprendizado da 2ª stack, anotado como limitação) | R2→R5 | log de horas |
| Aderência ao contrato | 20 | fidelidade ao contrato v1 sem retrabalho | divergências detectadas pela suíte de paridade (menor = melhor) | R4 | suíte de paridade |
| DX e documentação automática | 15 | ergonomia do dia a dia e documentação viva | checklist estruturado: /docs automático, ergonomia de validação, qualidade das mensagens de erro, setup | R5 | checklist DX |
| Esforço por componente paradigmático | 10 | quanto custa cada padrão de domínio em cada banco	delta de esforço nos componentes: pistas (embed vs FK+JOIN), mandado (subdoc vs 1:1+UNIQUE), dicionário ($jsonSchema vs ENUM) | R5 | log de horas + análise |
| Maturidade das bibliotecas | 5 | risco de longo prazo das dependências | avaliação qualitativa: lifecycle, comunidade, licenças, histórico de breaking changes | R5 | análise |

Pesos somam 100. Justificativa dos pesos em uma linha cada:

- **Performance 25 = Desenvolvimento 25:** para APIs internas da casa, ocusto de construir (pago todo dia) pesa tanto quanto rodar (pago porrequest). Nenhuma das duas domina sozinha a decisão.
- **Aderência 20:** é o Requisito A do projeto — uma stack que entrega ocontrato com menos atrito é a que vira padrão com menos dor.
- **DX 15:** documentação automática e ergonomia são os multiplicadoresdo time inteiro (onboarding, manutenção, revisão).
- **Paradigmático 10:** peso menor porque informa o mapa mais que ovencedor — mas garante que o custo de modelagem entre na conta.
- **Maturidade 5:** critério de desempate prático — ambas as stacks usambibliotecas canônicas e maduras (ADR-005); diferenças aqui são pequenas.

## 3. Regra de desempate
Empate técnico = delta ≤ 5 pontos na pontuação final. Nesse caso, decide:

1. Documentação automática (a stack que documentar melhor ganha)
2. Curva do time (a stack em que o time chega mais rápido ganha)

Definido antes das medições (mitigação do R4 do card do projeto: risco deresultado inconclusivo). Consistente com o contexto: o time precisa ficarbilíngue, e empate técnico com DX superior é vitória prática.

## 4. Análise de sensibilidade
Método: ±10% no peso de cada critério (um por vez, redistribuindo adiferença proporcionalmente aos demais), avaliando se a vencedora trocaem cenário ilustrativo.

Resultado: em nenhum cenário testado a vencedora troca. A matriz éestável no intervalo — a decisão não dependerá de ajuste fino de pesos.Se a R5 revelar delta ≤ 5 na pontuação real, o desempate (seção 3) jáestá definido — a matriz não precisa de reforma no meio da medição.

Nota: sensibilidade calculada sobre cenário ilustrativo (pontuaçõeshipotéticas plausíveis). Recomendado re-executar com as pontuações reaisda R5 como verificação final — 20 minutos de planilha.

## 5. Exclusões deliberadas (para não voltarem como dúvida)
- **Onboarding/contratação:** peso especulativo no contexto atual (timepequeno, lab solo). Candidato de v2 se o contexto mudar (registro naatividade 9 e no backlog).
- **Custo de infraestrutura:** ambas rodam em container local; diferençade custo é nula no contexto do lab.
- **"Famosidade"/hype:** excluído por definição — o lab existe parasubstituir exatamente esse critério por evidência.

## 6. Formato de preenchimento (R5)
Cada célula da pontuação recebe: nota 0–10 com fonte obrigatória(medição, log, suíte ou checklist). Número sem fonte não entra. Apontuação final = Σ(nota × peso/100) por stack, exibida com as fontes.O relatório da R5 apresenta: matriz preenchida, mapa de paradigma(critério 5 detalhado), registro de horas e a recomendação formal.

## 7. Ciclo de vida deste documento
| Evento | O que acontece |
| :--- | :--- |
| Aprovação | registro em aprovacao-matriz-v1.md; status → aprovada |
| Congelamento | congela junto do contrato (tag R1) |
| Preenchimento | notas com fonte; sensibilidade re-executada com dados reais |
| Mudança de pesos | NUNCA após início das medições; nova versão + ADR |

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 13-10-2026 | Primeira versão  | 	Proposta da atividade "Propor a matriz de decisão de stacks" | 	Define como a stack padrão será eleita | Emershow |