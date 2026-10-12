Número do ADR: 003<br>
Data: 12-10-2026<br>
Responsável: Equipe Dev - Projeto Onde no Banco de Dados Está Carmen Sandiego?<br>
Status: 🟢 Aceito

## Contexto
Na mecânica do jogo, quando o detetive abre um caso (POST /cases), o sistema sorteia o culpado e o roteiro completo da fuga (5 cidades) — e grava tudo no banco naquele momento. A partir daí, o jogo é o detetive descobrindo, pista por pista, o que o banco já sabe desde o início.

O problema central é: a resposta mora no banco a uma consulta de distância, mas nenhuma resposta pública pode entregá-la — senão o jogo morre, e o requisito mais didático do lab vira furo.

Sem regra explícita, a proteção dependeria de atenção individual ("todo mundo lembra de não selecionar culprit_id") — que é exatamente o tipo de defesa que falha em escala. Precisávamos decidir: cuidado informal ou regra de primeira classe?

## Decisão
Tratar o anti-spoiler como requisito funcional (Requisito I do projeto), com três braços:

1. **A resposta mora no banco desde o sorteio:** o caso é gravado completo — culpado, itinerário das 5 cidades, qual característica cada cidade revela, e quais pistas já foram descobertas. O estado do jogo é persistido, não calculado em tempo real.
2. **Toda consulta pública exclui os campos sensíveis:** no PostgreSQL, o SELECT simplesmente não inclui as colunas proibidas e filtra discovered = true (só pistas já encontradas); no MongoDB, usa-se a projection — o mecanismo que escolhe exatamente quais campos do documento viajarão na resposta.
3. **A suíte (R4) inclui casos negativos:** em toda resposta de caso, a suíte verifica a ausência dos campos proibidos (culprit_id, pistas futuras, característica a revelar). Vazamento vira teste vermelho com o nome do campo exposto.

## Justificativa
- **Problema real de engenharia:** "proteger dados que existem no banco mas não podem sair" é o dilema de sistemas de saúde, bancos e RH com dados sensíveis. O lab exerce o mesmo músculo num domínio lúdico — e as duas stacks o resolvem com técnicas nativas diferentes, o que enriquece a comparação.
- **Auditabilidade do jogo:** com o sorteio gravado, dá para conferir depois se o caso foi justo ("a pista realmente apontava a cidade certa?") — integridade que a computação em tempo real não oferece.
- **Testável por construção:** transformado em requisito com casos negativos, o anti-spoiler deixa de ser confiança e passa a ser evidência — a cada execução da suíte.
- **Fidelidade ao original:** no jogo de 1985, o computador da Interpol sabia a resposta e cabia ao detetive extraí-la — o banco é o computador da Interpol.

## Alternativas consideradas
**Alternativa 1: Resposta calculada em tempo real (não persistir o culpado)**<br>
Descrição: o caso gravaria apenas as pistas descobertas; o culpado seria derivado delas quando o mandado fosse emitido.

**Por que foi descartada?**<br>
- Perde a auditoria do sorteio ("foi justo?") — impossível conferir o caso após o fato
- O reset de caso viraria um pesadelo de estado derivado
- O exercício didático de proteção de dados desapareceria: sem dados sensíveis no banco, não há o que proteger — o requisito I se auto-anula

**Alternativa 2: Camada de DTO com whitelist centralizada**<br>
Descrição: um módulo separado listando, para cada endpoint, os campos permitidos na resposta.<br>

**Por que foi descartada?**<br>
- É essencialmente a técnica adotada, formalizada em módulo — 9 endpoints não pagam a abstração
- Mantida como disciplina por endpoint, com a suíte como rede de segurança

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Requisito testável:** vazamento vira teste vermelho, não segredo compartilhado entre devs. | **Disciplina por endpoint:** cada consulta nova precisa "lembrar" da regra — o risco de esquecimento é permanente. |
| **Comparação enriquecida:** SELECT com colunas omitidas vs projection — o mesmo problema, duas terapias nativas, matéria do mapa de paradigma. | **Sem defesa centralizada:** diferente de um filtro automático global, a proteção depende de cada query ser escrita corretamente. |
| **Jogo íntegro:** não há como trapacear espionando a API — o detetive joga limpo ou não joga. | **Falso senso de segurança:** os campos existem no banco; um console aberto por um curiosó lê tudo — a proteção é da API, não do banco. |
| **Reset limpo:** caso completo gravado = apagar caso = jogo zerado, sem estado residual. | **Warrant gravado:** mandados rejeitados ficam registrados (com as características tentadas) — decisão de gameplay que precisa respeitar o anti-spoiler. |

## Mitigações
- **Casos negativos em toda resposta de caso (R4):** a verificação de ausência roda em todos os testes, sempre — o esquecimento humano tem uma rede automatizada atrás.
- **Checklist de revisão:** item fixo na revisão de código: "esta consulta expõe campo de spoiler?".
- **O contrato como cercado:** a especificação OpenAPI não modela os campos sensíveis — o que não existe no contrato não deveria existir na resposta.
- **Warrant sem dica:** o mandado rejeitado grava a tentativa mas nunca revela o que errou — a decisão de gameplay foi desenhada dentro da cerca do anti-spoiler.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 12-10-2026 | Primeira versão  | Documentar o anti-spoiler como requisito funcional | Protege a integridade do jogo e o exercício didático central | Emershow |