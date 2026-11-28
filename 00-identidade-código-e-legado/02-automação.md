## ⚙️ No controle do próprio ritmo

Este guia apresenta os procedimentos de configuração de workflows e pipelines manuais, monitoramento de vulnerabilidades e atualização de dependências no GitHub e no GitLab.

Consulte os pré-requisitos no [README.md](README.md) antes de começar.

---

## 1. GitHub Actions

### Configuração

Dentro do repositório de testes, crie o diretório de workflows e o arquivo de configuração.

```bash
mkdir -p .github/workflows
nano .github/workflows/lab.yml
```

Adicione o conteúdo abaixo:

```yaml
name: Paranaue Labs

on:
  workflow_dispatch:

jobs:
  teste:
    runs-on: ubuntu-latest
    steps:
      - name: Executar teste
        run: echo "Paranaue Labs - GitHub Actions"
```

Arquivo de exemplo: [github-actions.yml](examples/github-actions.yml).

| Parâmetro | Finalidade |
|---|---|
| `workflow_dispatch` | Permite executar o workflow manualmente. |
| `jobs` | Define os trabalhos que serão executados. |
| `runs-on` | Define o ambiente de execução. |
| `steps` | Define as etapas de cada job. |

Caso já exista um workflow, ajuste apenas os gatilhos do bloco `on`, preservando os jobs existentes.

### Implementação

```bash
git add .github/workflows/lab.yml
git diff --cached
git commit -m "Configura workflow manual"
git push
```

O arquivo deve estar na branch padrão do repositório. Caso ela esteja protegida, utilize um pull request.

### Execução e validação

1. Acesse a aba **Actions**.
2. Selecione o workflow **Paranaue Labs**.
3. Clique em **Run workflow**.
4. Selecione a branch e confirme.
5. Abra o job `teste` e consulte o log.

**Resultado esperado:**

```text
Paranaue Labs - GitHub Actions
```

O workflow deve finalizar com sucesso.

As notificações podem ser ajustadas em **Settings → Notifications** nas configurações da conta.

---

## 2. GitLab CI/CD

### Configuração

Acesse **Settings → CI/CD → Runners** e confirme que existe um runner Linux disponível, compatível com a execução de imagens de contêiner.

Na raiz do repositório de testes, crie ou edite o arquivo:

```bash
nano .gitlab-ci.yml
```

Adicione o conteúdo:

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "web"'
    - when: never

stages:
  - test

teste:
  stage: test
  image: alpine:3
  script:
    - echo "Paranaue Labs - GitLab CI/CD"
```

Arquivo de exemplo: [gitlab-ci.yml](examples/gitlab-ci.yml).

| Parâmetro | Finalidade |
|---|---|
| `workflow: rules` | Define quando o pipeline pode ser criado. |
| `CI_PIPELINE_SOURCE == "web"` | Permite a criação pela interface. |
| `when: never` | Impede a criação por outros eventos. |
| `stages` | Define as etapas do pipeline. |
| `image` | Define a imagem utilizada pelo runner. |
| `script` | Define os comandos executados pelo job. |

Caso já exista um pipeline, ajuste o bloco `workflow`, preservando os demais jobs e configurações. Os jobs também precisam permitir a execução via interface.

### Implementação

```bash
git add .gitlab-ci.yml
git diff --cached
git commit -m "Configura pipeline manual"
git push
```

### Execução e validação

1. Acesse **Build → Pipelines**.
2. Clique em **New pipeline**.
3. Selecione a branch e confirme.
4. Abra o job `teste` e consulte o log.

**Resultado esperado:**

```text
Paranaue Labs - GitLab CI/CD
```

O pipeline deve finalizar com sucesso.

---

## 3. Dependabot — GitHub

O Dependabot atua em três frentes:

- **Dependabot Alerts:** Identificação de vulnerabilidades conhecidas.
- **Dependabot Security Updates:** Propostas de atualização para corrigir vulnerabilidades.
- **Dependabot Version Updates:** Propostas de atualização de versões.

### Configuração

No repositório, acesse **Settings → Advanced Security**.

Habilite ou confirme:

- Dependency graph.
- Dependabot alerts.
- Dependabot security updates.

Para configurar as atualizações de versões, crie o arquivo:

```bash
mkdir -p .github
nano .github/dependabot.yml
```

Exemplo para projetos que utilizam Terraform, GitHub Actions e Docker:

```yaml
version: 2

updates:
  - package-ecosystem: "terraform"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "github-actions"
    directory: "/"
    schedule:
      interval: "weekly"

  - package-ecosystem: "docker"
    directory: "/"
    schedule:
      interval: "weekly"
```

Arquivo de exemplo: [dependabot.yml](examples/dependabot.yml).

| Parâmetro | Finalidade |
|---|---|
| `version` | Versão do formato de configuração. |
| `package-ecosystem` | Tecnologia monitorada. |
| `directory` | Localização dos arquivos de dependências. |
| `interval` | Frequência de verificação. |

Mantenha apenas as tecnologias utilizadas no projeto.

O valor `/` representa a raiz do repositório. Para GitHub Actions, o Dependabot procura os workflows em `.github/workflows/`.

### Implementação

```bash
git add .github/dependabot.yml
git diff --cached
git commit -m "Configura Dependabot"
git push
```

O arquivo deve estar na branch padrão.

### Validação

- Acesse **Insights → Dependency graph → Dependabot** para consultar as verificações.
- Acesse **Security and quality → Dependabot** para consultar os alertas.
- Consulte os pull requests de atualização.

**Resultado esperado:** criação de pull requests quando houver atualizações aplicáveis.

A ausência de pull requests não significa necessariamente um problema: as dependências podem estar atualizadas.

---

## 4. Dependency Scanning — GitLab

> **Requisito:** GitLab Ultimate.

O Dependency Scanning identifica vulnerabilidades conhecidas nas dependências suportadas pelo analisador.

### Configuração

Edite o arquivo `.gitlab-ci.yml` existente e acrescente:

```yaml
include:
  - template: Jobs/Dependency-Scanning.v2.gitlab-ci.yml

variables:
  AST_ENABLE_MR_PIPELINES: "false"
```

Arquivo de exemplo: [gitlab-dependency-scanning.yml](examples/gitlab-dependency-scanning.yml).

A variável `AST_ENABLE_MR_PIPELINES` foi desabilitada neste exemplo para adequar a análise à estratégia de pipelines de branch acionados manualmente.

Caso já existam blocos `include` ou `variables`, acrescente as entradas aos blocos existentes.

Certifique-se de que:

- A etapa `test` está disponível.
- Existe um runner compatível.
- O projeto utiliza arquivos de dependências suportados pelo analisador.

Nem todas as tecnologias monitoradas pelo Dependabot possuem cobertura equivalente no GitLab.

### Implementação

```bash
git add .gitlab-ci.yml
git diff --cached
git commit -m "Configura Dependency Scanning"
git push
```

### Execução e validação

1. Acesse **Build → Pipelines → New pipeline**.
2. Execute o pipeline da branch padrão.
3. Consulte os jobs e artefatos de Dependency Scanning.
4. Acesse **Secure → Vulnerability report**.
5. Consulte também a lista de dependências em **Secure → Dependency list**.

**Resultado esperado:** geração do inventário de dependências (SBOM) e, quando aplicável, dos resultados de análise de vulnerabilidades.

---

## 5. Renovate — GitLab

O Renovate é uma ferramenta externa que automatiza propostas de atualização de dependências por meio de merge requests.

### Instalação hospedada

Para projetos em grupos do GitLab.com:

1. Acesse a [Mend Developer Platform](https://developer.mend.io).
2. Siga as instruções de instalação para GitLab.com.
3. Autorize o grupo e os projetos desejados.
4. Consulte o merge request inicial de configuração.

Caso o projeto esteja em um namespace pessoal não atendido pela instalação hospedada, utilize a alternativa self-hosted descrita abaixo.

### Configuração

Crie ou edite o arquivo `renovate.json` na raiz do repositório.

```json
{
  "extends": ["config:recommended"],
  "automerge": false
}
```

Arquivo de exemplo: [renovate.json](examples/renovate.json).

- `extends`: aplica as configurações recomendadas.
- `automerge`: desabilita o merge automático pelo bot.

Revise e integre a configuração à branch padrão.

> Criar o arquivo `renovate.json` não ativa o Renovate. É necessário ter um bot instalado e em execução.

### Execução local (self-hosted)

Alternativa para testar o Renovate em projetos pessoais.

Requisitos:

- Docker instalado.
- Conta autorizada no projeto.
- Token de acesso compatível com o Renovate, com escopo `api` e validade definida.

Prefira uma identidade exclusiva para o bot, com acesso restrito ao projeto.

Após enviar o arquivo `renovate.json` para a branch padrão, execute em Bash:

```bash
# Informe o token sem exibi-lo no terminal
read -rsp 'Token do Renovate: ' RENOVATE_TOKEN
printf '\n'
export RENOVATE_TOKEN

# Simule as atualizações sem criar merge requests
docker run --rm \
  -e RENOVATE_TOKEN \
  -e RENOVATE_PLATFORM=gitlab \
  -e RENOVATE_ENDPOINT=https://gitlab.com/api/v4/ \
  -e RENOVATE_DRY_RUN=full \
  renovate/renovate usuario/meu-projeto

# Remova a variável da sessão
unset RENOVATE_TOKEN
```

Substitua `usuario/meu-projeto` pelo caminho completo do projeto no GitLab.com.

Confira os logs da simulação.

Para executar de fato, repita o procedimento sem a linha `-e RENOVATE_DRY_RUN=full`, somente após validar o projeto e as permissões utilizadas.

O Renovate poderá criar branches e merge requests.

Essa execução é pontual. Para automação recorrente, configure um agendamento em ambiente controlado e fixe uma versão da imagem utilizada.

Nunca versione o token.

### Validação

Consulte os merge requests criados pelo Renovate e revise as atualizações propostas.

**Resultado esperado:** propostas de atualização quando existirem dependências desatualizadas.

---

## ⚠️ Considerações

- A execução exclusivamente manual é uma escolha para o contexto deste laboratório.
- Em ambientes produtivos e colaborativos, preserve as validações automáticas necessárias.
- Revise e teste as atualizações propostas pelo Dependabot e pelo Renovate antes do merge.
- A ausência de vulnerabilidades conhecidas não garante que o projeto esteja livre de riscos.

---

## 📚 Referências

- [GitHub Actions](https://docs.github.com/en/actions/)
- [GitLab CI/CD — Workflow](https://docs.gitlab.com/ci/yaml/workflow/)
- [Dependabot](https://docs.github.com/en/code-security/dependabot)
- [Dependency Scanning — SBOM](https://docs.gitlab.com/user/application_security/dependency_scanning/dependency_scanning_sbom/)
- [Renovate — GitLab](https://docs.renovatebot.com/modules/platform/gitlab/)
- [Renovate — Execução](https://docs.renovatebot.com/getting-started/running/)

---

[Voltar ao README](README.md)