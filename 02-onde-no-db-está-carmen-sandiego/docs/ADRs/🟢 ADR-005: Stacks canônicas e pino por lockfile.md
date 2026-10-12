Número do ADR: 005<br>
Data: 12-10-2026<br>
Responsável: Equipe Dev - Projeto Onde no Banco de Dados Está Carmen Sandiego?<br>
Status: 🟢 Aceito

## Contexto
Definidas as duas stacks a comparar, faltava cravar versões exatas e a forma de garanti-las ao longo do tempo.

O problema central é: num lab cujo Requisito D é "qualquer pessoa sobe o mesmo ambiente", depender de "instala a versão mais nova" é convite ao desastre — o lab funcionaria hoje e quebraria em seis meses, silenciosamente, quando as versões "mais novas" mudarem.

Versões importam: Node 22 se comporta diferente do Node 20; Mongoose 8 tem API diferente do Mongoose 6; e bibliotecas de banco com componentes nativos (compilados) podem nem instalar em certas bases de imagem. O spike de sanidade (atividade 2 — experimento rápido e descartável para validar premissas) confirmou que as versões escolhidas constroem imagens Docker limpas e conectam nos bancos do compose.

## Decisão
Adotar as stacks canônicas de mercado, com versões e imagens fixadas:

|  | python-api | node-api |
| :--- | :--- | :--- |
| Linguagem | Python 3.13 | Node.js 22 LTS|
| Framework | FastAPI | Express 4 |
| Acesso a dados | SQLAlchemy 2.0 + psycopg 3 | Mongoose 8 |
| Banco | PostgreSQL 17 | MongoDB 8 |
| Imagem base | python:3.13-slim | node:22-alpine |

Com duas regras de fixação:

1. **Lockfile commitado:** as listas de dependências (package-lock.json no Node, uv.lock no Python) registram a versão exata de cada biblioteca — não faixas como "2.x", que o instalador resolve de forma diferente a cada dia. Quem clona o repo instala exatamente o que foi testado.
2. **Imagens por tag major:** os Dockerfiles referenciam node:22-alpine, nunca node:latest — "latest" ("a mais recente") muda sem aviso e quebra em silêncio.

Sobre a diferença de bases (alpine vs slim): são duas distribuições Linux enxutas para containers. A Alpine é minúscula, mas usa uma forma de compilar programas (musl) para a qual nem toda biblioteca Python tem versão pré-compilada — o que exigiria instalar compiladores na imagem. A slim, baseada em Debian, aceita as versões prontas (wheels) do psycopg. Resultado: zero "build nativo" (compilação durante a instalação) nos dois lados — instalação rápida e frágil-zero.

## Justificativa
- **Pares canônicos:** Express+Mongoose e FastAPI+SQLAlchemy são o que o mercado roda de fato — a comparação precisa refletir o mundo real, não combinações exóticas que ninguém usa.
- **Reprodutibilidade como requisito:** lockfile + tag major eliminam o clássico "na minha máquina funciona" — as versões não são sugestão, são parte do código.
- **Zero build nativo:** psycopg[binary] entrega a wheel pronta em slim; Express/Mongoose são JavaScript puro em alpine. Nenhum dos lados precisa de toolchain de compilação.
- **Coerência com o ambiente validado:** as mesmas imagens constroem a suíte, o CI e as 4 VMs do sweep — o que foi testado é o que roda.

## Alternativas consideradas
**Alternativa 1: Fastify no lugar do Express**<br>
Descrição: framework Node mais moderno e performático.<br>

**Por que foi descartada?**<br>
- Par menos consolidado no mercado — e o lab compara o que os times realmente usam
- A troca está registrada no card do projeto (decisão de escopo, não técnica)

**Alternativa 2: Drivers puros de banco (sem ORM)**<br>
Descrição: usar pg e mongodb diretamente, sem camada de mapeamento.<br>

**Por que foi descartada?**<br>
- ORM (a biblioteca que traduz entre objetos do código e registros do banco) canônico faz parte do par que se compara — removê-lo mudaria a pergunta do experimento
- O que um time real usaria inclui o ORM; comparar sem ele é comparar outra coisa

**Alternativa 3: Faixas semânticas de versão (^2.1.0)**<br>
Descrição: fixar versão mínima e aceitar qualquer atualização compatível.<br>

**Por que foi descartada?**<br>
- O instalador pode elevar versões sem ninguém perceber — quebra o Requisito D
- A reprodutibilidade exige exato, não "compatível"

**Alternativa 4: python:3.13-alpine (base única nas duas stacks)**<br>
Descrição: padronizar as duas imagens na Alpine.<br>

**Por que foi descartada?**<br>
- musl + dependências nativas do psycopg é dor conhecida (compilação na instalação)
- slim resolve com wheel pronta — a "assimetria" das bases é escolha técnica documentada, não descuido

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Build reprodutível:** mesmo clone, mesmo resultado — hoje e daqui a meses. | **Disciplina de commit conjunto:** código e lockfile sempre juntos — esquecer o lockfile quebra o build dos outros. |
| **Instalação limpa:** zero compilação nativa — builds rápidos e menos frágeis. | **Atualização deliberada:** elevar versão deixa de ser automático e vira decisão registrada. |
| **Ambiente coerente:** CI, suíte e as 4 VMs sobem exatamente o que foi testado no spike. | **Lockfiles divergem sem disciplina:** dois arquivos a manter em sincronia com o código. |
| **Curva de leitura baixa:** pares canônicos = material abundante, onboarding facilitado. | **Inchaço controlado:** imagem slim é maior que alpine (~50MB) — trade-off aceito por eliminar build nativo. |

## Mitigações
- **CI rejeita lockfile desatualizado:** pipeline falha se o código mudou sem o lockfile acompanhar — o esquecimento vira erro visível no push, não no colega.
- **Atualização no backlog com data:** renovar dependências é item agendado, não emergência.
- **Sweep re-executando o par imagem/lockfile:** as 4 VMs sobem o mesmo par validado — desvio de ambiente aparece na varredura, não no usuário.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 12-10-2026 | Primeira versão  | Documentar stacks canônicas e pino por lockfile | Garante reprodutibilidade do experimento (Requisito D) | Emershow |