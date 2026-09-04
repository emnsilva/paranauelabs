Número do ADR: 003<br>
Data: 14-08-2026<br>
Responsável: Equipe de SRE/DevOps - Projeto IaC Multi-Cloud<br>
Status: 🟢 Aceito

## Contexto
O projeto IaC Railways consiste em uma matriz complexa de 8 combinações (2 ferramentas de IaC x 4 provedores de nuvem). Além disso, o repositório paranauelabs é um monorepo projetado para hospedar múltiplos laboratórios no futuro, utilizando o GitHub Actions como motor principal de CI/CD (com planejamento futuro para Jenkins).

O problema central é: como estruturar os diretórios e a esteira de CI/CD (GitHub Actions) para que o código de infraestrutura não se misture com o código de automação, garantindo que pipelines de laboratórios ou ferramentas diferentes não sejam acionados desnecessariamente (desperdício de minutos de CI)? Adicionalmente, qual versão do binário Terraform/OpenTofu deve ser fixada para garantir 100% de compatibilidade?

## Decisão
Adotar uma estrutura de diretórios baseada em "Raiz por Ferramenta, subdividida por Cloud" e uma Arquitetura de CI/CD isolada por Workflow no GitHub Actions. Fixar a versão do binário Terraform em 1.16.0 e OpenTofu em 1.16.2.

A implementação seguirá as seguintes diretrizes:

1. **Estrutura de Diretórios:**
    - Laboratórios na raiz prefixados numericamente (ex: 01-iac-railways/).
    - Dentro do lab, diretórios raiz por ferramenta (terraform/, opentofu/), subdivididos por cloud (aws/, azure/, gcp/, oci/).
    - Workflows do GitHub Actions isolados na pasta .github/workflows/ na raiz do repositório.
2. **Arquitetura de CI/CD (GitHub Actions):**
    - Workflows Separados: Criação de arquivos de workflow separados por ferramenta (ex: tfc-pipeline.yml, tofu-pipeline.yml).
    - Gatilhos Manuais (workflow_dispatch): Para garantir governança (GMUD) e evitar execuções acidentais, os pipelines são acionados manualmente via interface do GitHub, utilizando dropdowns (inputs) para selecionar o Ambiente (dev, staging, prod) e a Ação (deploy ou destroy).
    - Isolamento de Jobs: Utilização da instrução needs para criar dependências (Validate -> Plan -> Apply) e if condicional para separar o caminho de deploy do caminho de destroy.
3. **Versionamento de Ferramenta:**
    - Fixar a versão 1.16.0 para o Terraform e 1.12.6 para o OpenTofu nas actions oficiais do GitHub (hashicorp/setup-terraform e opentofu/setup-opentofu).

## Justificativa
1. **Isolamento de Responsabilidades:** A estrutura "Raiz por Ferramenta" agrupa paradigmas semelhantes (HCL), facilitando a navegação e manutenção do código.
2. **Eficiência de CI/CD (FinOps):** A abordagem de workflows separados e gatilhos manuais via dropdowns garante que o usuário tenha controle total sobre o que e quando rodar, evitando o disparo de pipelines inteiros por um simples push de código (o que consumiria minutos do GitHub Actions desnecessariamente).
3. **Manutenibilidade:** Separar o código de infraestrutura (.tf) do código de automação (.github/workflows/) evita que arquivos fiquem escondidos no meio de pastas de módulos, mantendo o repositório limpo.
4. **UX do GitHub Actions:** O uso de workflow_dispatch com inputs (dropdowns) provê uma experiência visual excelente para o operador de DevOps, simulando o "botão de Play" manual que existe em outras ferramentas como o GitLab.
5. **Compatibilidade de Versão:** Fixar versões específicas garante que o código não quebre por alterações em releases futuros das ferramentas.

## Alternativas consideradas
**Alternativa 1: Estrutura "Raiz por Cloud, subdividida por Ferramenta"**<br>
Descrição: Ter pastas como aws/terraform, aws/opentofu, azure/terraform, etc.<br>

**Por que foi descartada?** <br>
Agrupar por cloud mistura paradigmas dentro da mesma pasta raiz e dificulta a criação de regras de gatilho do pipeline genéricas por ferramenta.

**Alternativa 2: Pipeline Monolítico (Arquivo Único)**<br>
Descrição: Um único arquivo de workflow gigante que roda a cada commit, detectando a pasta e disparando jobs condicionais.<br>

**Por que foi descartada?**<br>
O arquivo se tornaria ilegível rapidamente ao adicionar as 8 combinações de matriz. Além disso, o gatilho automático consome minutos de CI do GitHub a cada push, mesmo para alterações de documentação.

## Consequências
| POSITIVAS | NEGATIVAS/DESAFIOS |
| :--- | :--- |
| **Organização Escalável:** O repositório suporta a adição de novos laboratórios e novas clouds sem se tornar um caos visual. | **Trabalho Manual:** O operador precisa ir na aba Actions e clicar em "Run workflow" escolhendo os parâmetros. Não há deploy contínuo automático (o que é aceitável para laboratório/GMUD). |
| **Controle Total (GMUD):** O deploy nunca ocorre sem aprovação explícita e seleção correta de ambiente/ação. | **Sem Botão Mid-Pipeline:** Diferente do GitLab, o GitHub Actions não permite pausar no meio de um workflow para aprovação manual e depois continuar. A divisão em deploy ou destroy via dropdown resolve isso, mas exige duas execuções diferentes se quiser fazer os dois. |
| **Manutenção Simplificada:** Ajustar a versão do Terraform ou do OpenTofu exige editar apenas a action correspondente. | **Duplicação de Código YAML:** O código do GitHub Actions tende a repetir blocos de steps se não usar Reusable Workflows, mas para o escopo do lab é aceitável. |

## Mitigações
- **Documentação Clara:** O README do laboratório detalha como acionar os workflows e a sequência de etapas.
- **Ambientes (Environments):** Uso do recurso de Environments do GitHub (dev, staging, prod) para injetar variáveis e secrets automaticamente baseado no dropdown escolhido, reduzindo a complexidade do código YAML.

## Registro de mudanças
| Data       | O que mudou?     | Por que mudou?                                                                 | Impacto | Feito por... |
| ---------- | ---------------- | ------------------------------------------------------------------------------ | ------- | ------------ |
| 14-08-2026 | Primeira versão  | Documentar a decisão sobre a estrutura de diretórios, camadas de CI/CD e versionamento do binário | Estabelece a base de organização de código e automação para o projeto IaC | Emershow |
