Número do ADR: 002<br>
Data: 12-10-2026<br>
Responsável: Equipe Dev - Projeto Onde no Banco de Dados Está Carmen Sandiego?<br>
Status: 🟢 Aceito

## Contexto
Para o jogo funcionar, os dois bancos precisam nascer idênticos: mesmo dossiê da V.I.L.E. (21 bandidos com 5 características cada), mesmas 12 cidades com seus tesouros. Esse conteúdo inicial é a seed — a "semente" que o jogo planta para crescer.<br>

O problema central é: onde a seed mora, e quem a carrega para cada banco?<br>

Cada banco tem seu mecanismo nativo de carga inicial: o PostgreSQL aceita init.sql (script executado quando o container sobe pela primeira vez); o MongoDB, scripts .js. Se cada banco tivesse sua própria seed, existiriam duas cópias da mesma informação em formatos diferentes — e cópias divergem: alguém corrige um nome de um lado, esquece o outro, e a comparação do lab é sabotada silenciosamente, sem nenhum erro visível.

## Decisão
Adotar a seed única versionada no repositório como fonte de dados, com carga idempotente pelas próprias APIs:

1. data/seed.json é a única fonte — formato JSON, legível pelas duas stacks, versionado junto do contrato.
2. **Cada API traduz a seed para o seu banco no carregamento:** a node-api lê o JSON e insere documentos; a python-api lê o mesmo JSON e insere linhas. O arquivo é um; a tradução é responsabilidade de cada lado.
3. **Carga idempotente no startup:** cada API, ao iniciar, verifica se o banco está vazio; se sim, carrega a seed; se não, não faz nada (idempotente = repetir a operação não muda o resultado).
4. **POST /api/seed como reset manual:** apaga os casos (investigações em andamento), recarrega o dossiê e ressincroniza os geradores de ids (ADR-006) — o mesmo caminho de código do startup.
5. **Bancos nascem vazios no Docker:** nenhum init.sql, nenhum script mongo no compose. Toda carga, sempre, passa pelas APIs.

## Justificativa
- **Uma fonte elimina divergência por construção:** não é disciplina ("lembrar de atualizar os dois"), é arquitetura — só existe um lugar para estar errado.
- **Setup sem passo manual:** qualquer pessoa que subir o ambiente (colega, CI, recrutador avaliando o portfólio) chega ao estado correto automaticamente — clonar e subir basta.
- **Reset determinístico:** a suíte de paridade (R4) precisa de ponto de partida previsível entre bateria e bateria de testes; o reset por endpoint entrega isso.
- **A seed como contrato de dados:** congelada junto do contrato de API (atividade 13), garante que "dados iniciais" é decisão versionada, não estado casual de banco.

## Alternativas consideradas
**Alternativa 1: Carga nativa por banco (init.sql + script mongo)**<br>
Descrição: cada banco recebe seu arquivo de carga própria, executada automaticamente na primeira subida do container.<br>

**Por que foi descartada?**<br>
- Duas fontes da mesma verdade, em formatos diferentes, mantidas separadamente — a primeira divergência silenciosa destrói a comparação justa
- A seed deixaria de ser código versionado junto do contrato e viraria configuração de infraestrutura, com ciclo de vida separado
- Dificulta o reset (POST /api/seed): recriar containers para "resetar" é pesado e lento

**Alternativa 2: Seed por API (dois arquivos)**<br>
Descrição: cada API mantém seu próprio arquivo de dados iniciais.<br>

**Por que foi descartada?**<br>
- Mesmo defeito da alternativa 1, com um arquivo a mais para manter
- A "fonte única" seria apenas uma convenção de sincronização manual

**Alternativa 3: Ferramentas de migração (Alembic e similares)**<br>
Descrição: usar ferramenta de versionamento de schema e carga.<br>

**Por que foi descartada?**<br>
- Migração é ferramenta para evoluir a estrutura do banco ao longo do tempo (adicionar coluna, mudar tipo) — aqui a seed é um contrato congelado, sem evolução na v1
- Complexidade adicional sem benefício no escopo atual

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Idênticos por construção:** os dois bancos carregam o mesmo conteúdo porque leem o mesmo arquivo — comparação justa garantida na base. | **Tradutor duplicado:** cada API mantém seu código de JSON→banco — mais um ponto onde as implementações podem divergir (e que a suíte precisa cobrir). |
| **Setup de um passo:** clone e make up — sem seed manual, sem passos extras no README. | **Validação obrigatória no load:** a seed precisa ser checada ao carregar (unicidade das 5 características, valores do dicionário) — dois bandidos idênticos quebrariam o jogo. |
| **Reset determinístico:** mesmo procedimento, mesmo resultado, sempre — pré-requisito da suíte R4. | **Reset destrutivo:** POST /api/seed apaga investigações em andamento — comportamento de laboratório, precisa estar claro na documentação. |
| **Auditoria de dados:** "o que o jogo tinha no início?" é uma pergunta respondida abrindo um arquivo versionado. | **Carga na primeira subida:** o primeiro startup é mais lento (inserts de 33 registros + ressincronização) — custo irrelevante, mas real. |

## Mitigações
- **Validação no carregamento (ambos os lados):** unicidade das 5-tuplas e enums do dicionário conferidos no load — seed inválida derruba o startup com erro claro, na hora, em vez de corromper o jogo depois.
- **Um único caminho de carga por API:** startup e POST /api/seed usam a mesma função — não existe segunda rota de código onde a regra poderia ser esquecida.
- **Suíte determinística (R4):** casos de dossiê/seed comparam corpo exato — divergência de carga entre os bancos vira teste vermelho.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 12-10-2026 | Primeira versão  | Documentar a decisão da seed única com carga idempotente | Garante ponto de partida idêntico nos dois bancos | Emershow |