Número do ADR: 004<br>
Data: 12-10-2026<br>
Responsável: Equipe Dev - Projeto Onde no Banco de Dados Está Carmen Sandiego?<br>
Status: 🟢 Aceito

## Contexto
A afirmação central do lab: as duas stacks implementam exatamente a mesma API — mesmas rotas, mesmos formatos de resposta, mesmos códigos de status, mesmo envelope de erro.

O problema central é: sem prova, "mesmo contrato" é opinião.

Divergências sutis são o pão de cada dia de integração: uma API devolve {"erro": ...} e a outra {"error": ...}; uma valida campos numa ordem e devolve erro diferente; uma usa 400 onde a outra usa 404. Cada uma dessas passa despercebida em revisão de código e explode depois — e o entregável final do lab (o padrão de contrato para as próximas APIs da casa) nasceria sem lastro.

## Decisão
Provar a paridade com suíte automatizada de testes de contrato (construída na R4): cada teste dispara a mesma requisição contra as duas APIs e compara status + corpo da resposta.

A suíte reconhece duas naturezas de caso, porque o jogo tem uma parte previsível e uma parte sorteada:
1. Casos determinísticos — tudo que não depende de sorte: dossiê com e sem filtros, validações 400, 404, 405, reset de seed. Compara-se o corpo exato (com normalizações documentadas).
2. Casos estocásticos (estocástico = depende de sorteio) — abrir caso, viajar, emitir mandado. Como cada API sorteia culpados e itinerários próprios, os corpos divergem por natureza — compará-los palavra a palavra seria garantia de falso positivo. Compara-se então o formato (campos e tipos corretos) e os invariantes (regras que valem sempre: "a 1ª pista revela exatamente a característica 'sexo'", "campos de spoiler nunca aparecem", "pista nova só aparece após cidade correta").

Meta: ≥ 40 casos, 100% aprovados nas duas (Outcome 1 do projeto), execução por um comando, relatório de aprovado/reprovado por caso. A suíte roda em container (Bruno CLI) — a mesma ferramenta e imagem, local e no CI.

## Justificativa
- **Evidência substitui afirmação:** a paridade deixa de ser promessa e passa a ser fato verificável por qualquer um que rodar a suíte — incluindo o CI.
- **A divisão determinístico/estocástico é honesta:** o sorteio faz as respostas divergirem por design; fingir comparação exata ali geraria falsos positivos que desacreditariam a suíte toda. Invariantes são o contrato verdadeiro do comportamento aleatório.
- **O CI fecha o loop:** divergência quebrando o build é divergência corrigida antes de virar padrão adotado pelos times.
- **Reuso:** a suíte vira parte do padrão de contrato da casa — a próxima API já nasce com o modelo de como provar que cumpre o contrato.

## Alternativas consideradas
**Alternativa 1: Diff da especificação OpenAPI**<br>
Descrição: comparar as duas specs OpenAPI geradas por cada API.<br>

**Por que foi descartada?**<br>
- A spec valida a forma, não o comportamento: status reais, ordem de validação, corpo do erro em runtime não aparecem no diff
- As duas APIs sequer geram spec (elas implementam a spec canônica do contrato) — não há o que diffar

**Alternativa 2: Comparação manual por checklist**<br>
Descrição: um roteiro manual de chamadas, conferindo respostas a olho.<br>

**Por que foi descartada?**<br>
- Não escala, não é repetível, não roda no CI e não produz evidência auditável
- Sujeita a fadiga — exatamente o tipo de verificação onde o olho humano erra

**Alternativa 3: Ferramentas de contrato consumidor-produtor (Pact e similares)**<br>
Descrição: usar ferramentas consagradas de contract testing.<br>

**Por que foi descartada?**<br>
- São desenhadas para o cenário "consumidor declara o que espera; produtor prova que entrega" — o nosso cenário é "duas implementações devem ser idênticas entre si"
- Ferramenta errada para o problema: a solução aqui é comparativa, não declarativa

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Divergência com nome e endereço:** cada caso vermelho aponta exatamente onde as stacks divergem — debug dirigido. | **Custo de manutenção:** ~40 casos são código que precisa acompanhar o contrato. |
| **CI como guardião:** pipeline de paridade bloqueia mudanças que quebrem a equivalência. | **Normalização como ponto cego:** ignorar campos voláteis (datas, ids sorteados) pode esconder divergência real se mal definida. |
| **Padrão comprovado:** o entregável da casa sai do lab com evidência — não com confiança. | **Falso positivo em estocástico mal escrito:** invariantes mal escolhidos podem passar Bugs de comportamento. |
| **Relatório de decisão lastroado:** a matriz (R5) referencia a suíte como fonte dos números de aderência. | **Dependência da disciplina de rodar:** suíte que ninguém roda é papel — o CI existe para eliminar essa dependência. |

## Mitigações
- **Normalização documentada no contrato:** quais campos são voláteis e como a comparação os trata — a regra mora no documento, não escondida no comparador.
- **Pipeline de paridade no CI:** toda mudança roda a suíte contra as duas APIs; divergência bloqueia o merge.
- **Meta como piso:** o relatório mostra sempre casos/total — queda de cobertura é visível de imediato.
- **Revisão de invariantes:** os casos estocásticos são revisados com a mesma atenção que código de produção — invariantes fracos são bugs silenciosos.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 12-10-2026 | Primeira versão  | Documentar a paridade auditável por testes de contrato | Transforma a promessa central do lab em evidência verificável | Emershow |