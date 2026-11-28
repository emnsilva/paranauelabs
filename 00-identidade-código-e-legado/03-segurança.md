## 🛡️ Protegendo o que construímos

Este guia apresenta os procedimentos de implementação de camadas de proteção contra a exposição acidental de credenciais e informações sensíveis no GitHub e no GitLab.

Consulte os pré-requisitos no [README.md](README.md) antes de começar.

---

## 1. Secret Scanning e Push Protection — GitHub

### Configuração

1. Acesse o repositório no GitHub.
2. Navegue até **Settings → Advanced Security**.
3. Habilite ou confirme os seguintes recursos:
   - Secret scanning.
   - Push protection.
   - Validity checks, quando disponível.

| Recurso | Finalidade |
|---|---|
| Secret Scanning | Identifica possíveis credenciais expostas. |
| Push Protection | Bloqueia pushes contendo credenciais reconhecidas. |
| Validity Checks | Verifica se determinadas credenciais ainda estão ativas. |

Secret Scanning e Push Protection estão disponíveis gratuitamente em repositórios públicos. Outros cenários dependem do plano e das configurações disponíveis.

### Validação

1. Acesse **Security and quality → Secret scanning**.
2. Consulte os alertas existentes.
3. Verifique os resultados apresentados pela plataforma.

A ausência de alertas não garante que o repositório esteja livre de informações sensíveis.

---

## 2. Secret Push Protection — GitLab

> **Requisito:** GitLab Ultimate.

### Configuração

1. Acesse o projeto no GitLab.
2. Navegue até **Secure → Security configuration**.
3. Habilite **Secret push protection**.

### Validação

Retorne à página de configuração e confirme que o recurso está ativo.

**Resultado esperado:** pushes contendo credenciais reconhecidas podem ser bloqueados antes de chegar ao repositório.

---

## 3. Pipeline Secret Detection — GitLab

Disponível nos planos Free, Premium e Ultimate, com diferenças na apresentação dos resultados.

### Configuração

Edite o arquivo `.gitlab-ci.yml` na raiz do repositório e acrescente:

```yaml
include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml
```

Caso já exista um bloco `include`, adicione o template à lista existente.

Certifique-se de que a etapa `test` está disponível e de que existe um runner compatível.

### Exemplo completo

Caso tenha seguido o guia de automação, o arquivo poderá ficar assim:

```yaml
workflow:
  rules:
    - if: '$CI_PIPELINE_SOURCE == "web"'
    - when: never

stages:
  - test

variables:
  AST_ENABLE_MR_PIPELINES: "false"

include:
  - template: Jobs/Secret-Detection.gitlab-ci.yml

teste:
  stage: test
  image: alpine:3
  script:
    - echo "Paranaue Labs"
```

Arquivos disponíveis:

- [Secret Detection — Todos os planos](examples/gitlab-ci-security.yml)
- [Secret Detection + Dependency Scanning — Ultimate](examples/gitlab-ci-security-ultimate.yml)

Escolha apenas um dos exemplos e preserve as configurações existentes no projeto.

### Implementação

```bash
git add .gitlab-ci.yml
git diff --cached
git commit -m "Configura Secret Detection"
git push
```

### Execução e validação

1. Acesse **Build → Pipelines → New pipeline**.
2. Selecione a branch padrão.
3. Execute o pipeline.
4. Abra o job `secret_detection`.
5. Consulte os artefatos gerados.

**Resultado esperado:** geração do relatório `gl-secret-detection-report.json`.

No plano Ultimate, consulte também o relatório de vulnerabilidades da plataforma.

### Análise inicial do histórico

Para analisar o histórico do repositório:

1. Crie um novo pipeline pela interface.
2. Adicione a variável:

```text
Key:   SECRET_DETECTION_HISTORIC_SCAN
Value: true
```

3. Execute o pipeline.
4. Consulte novamente o relatório.

Caso a interface não permita adicionar variáveis de pipeline, configure temporariamente a variável no arquivo `.gitlab-ci.yml` e remova-a após a análise.

Não é necessário repetir a análise completa do histórico a cada execução.

> **Atenção:** se o pipeline estiver configurado para execução exclusivamente manual, a análise também dependerá desse acionamento.

---

## 4. Teste de Push Protection — GitHub e GitLab

Utilize exclusivamente um repositório de testes com a proteção habilitada.

Nunca utilize credenciais reais.

### Preparação

```bash
# Confira se está no repositório correto
git remote -v
git status

# Prossiga somente se não houver alterações pendentes
git switch -c teste-push-protection
```

### Criação de uma credencial fictícia

No GitHub, utilize a amostra fictícia disponibilizada no [exercício oficial de proteção de segredos](https://docs.github.com/en/get-started/learning-to-code/storing-your-secrets-safely).

No GitLab, utilize o exemplo fictício do [tutorial oficial de Push Protection](https://docs.gitlab.com/user/application_security/secret_detection/push_protection_tutorial/).

```bash
# GitHub: substitua pelo valor fictício do exercício oficial
printf '%s\n' 'AMOSTRA_FICTICIA_DO_GITHUB' > teste-secret.txt

# OU GitLab
printf '%s\n' 'glpat-12345678901234567890' > teste-secret.txt
```

Execute apenas o comando correspondente à plataforma.

Uma sequência arbitrária de caracteres pode não ser reconhecida como credencial.

### Teste

```bash
git add teste-secret.txt
git diff --cached
git commit -m "Teste de Push Protection"

# Tente enviar o commit
git push -u origin teste-push-protection
```

**Resultado esperado:** push rejeitado com uma mensagem indicando a detecção de credenciais, caso o padrão seja reconhecido.

### Correção do commit

Execute os comandos abaixo somente se o push tiver sido bloqueado pela proteção e a credencial fictícia estiver apenas no último commit.

```bash
# Confira se não existem outras alterações pendentes
git status

# Remova o arquivo fictício
git rm teste-secret.txt

# Substitua o último commit pelo conteúdo corrigido
git commit --amend --no-edit --allow-empty

# Confira os arquivos presentes no commit corrigido
git ls-tree -r --name-only HEAD
```

O arquivo `teste-secret.txt` não deve aparecer na listagem.

```bash
# Envie o commit corrigido
git push -u origin teste-push-protection
```

**Resultado esperado:** push aceito, caso não existam outras violações.

Caso o push original seja aceito, revise as configurações e o padrão de teste utilizado. Descarte o repositório de testes após a análise.

### Tratamento de credenciais reais expostas

Em caso de exposição:

1. Revogue a credencial imediatamente.
2. Gere uma nova credencial.
3. Investigue possíveis utilizações indevidas.
4. Avalie a necessidade de limpeza do histórico.

Remover um arquivo em um novo commit não elimina as informações dos commits anteriores.

---

## 5. Gitignore — GitHub e GitLab

O `.gitignore` define quais arquivos não rastreados devem ser ignorados pelo Git.

### Configuração

Na raiz do repositório, crie ou edite o arquivo:

```bash
nano .gitignore
```

Preserve as regras existentes e acrescente os padrões necessários ao projeto.

Exemplo para laboratórios de infraestrutura como código:

```gitignore
# Terraform / OpenTofu
.terraform/
*.tfstate
*.tfstate.*
crash.log
crash.*.log
override.tf
override.tf.json
*_override.tf
*_override.tf.json
*.tfvars
*.tfvars.json
*.plan
*.tfplan
.plan

# Pulumi
Pulumi.*.yaml

# Secrets e credenciais
.env
.env.*
!.env.example
!.env.sample
*.pem
*.key
*.ppk
*.p12
*.pfx
*.jks
credentials.json
service-account*.json
aws-credentials

# IDE e editores
.vscode/
.idea/
*.swp
.DS_Store

# Logs e arquivos temporários
*.log
logs/
tmp/

# Dependências e cache
node_modules/
venv/
.venv/
__pycache__/
*.pyc
```

Arquivo de exemplo: [gitignore.example](examples/gitignore.example).

### Entendendo as regras

| Regra | Comportamento |
|---|---|
| `*.log` | Ignora arquivos com extensão `.log`. |
| `node_modules/` | Ignora diretórios chamados `node_modules`. |
| `.env.*` | Ignora arquivos correspondentes ao padrão. |
| `!.env.example` | Cria uma exceção à regra anterior. |

Adapte as regras às tecnologias utilizadas.

A exclusão dos arquivos de stack do Pulumi é uma escolha conservadora deste exemplo. Avalie quais configurações precisam ser versionadas.

O arquivo `.terraform.lock.hcl` deve permanecer versionável.

Arquivos de exemplo não devem conter credenciais reais.

### Validação

```bash
# Verifique a regra aplicada a um arquivo fictício
git check-ignore -v .env.teste-paranaue

# Identifique arquivos já rastreados que deveriam ser ignorados
git ls-files -ci --exclude-standard
```

**Resultado esperado:**

- O primeiro comando apresenta a regra responsável pela exclusão.
- O segundo não apresenta resultados caso não existam arquivos rastreados correspondentes às regras.

### Remoção de arquivos já versionados (opcional)

Caso o arquivo `.env` já esteja sendo rastreado e você deseje removê-lo do versionamento:

```bash
git rm --cached .env
```

O comando preserva a cópia local do arquivo, mas não remove seu conteúdo dos commits anteriores.

### Implementação

```bash
git add .gitignore

# Revise o conteúdo que será incluído no commit
git status
git diff --cached

git commit -m "Configura gitignore"
git push
```

**Resultado esperado:** arquivos não rastreados correspondentes às regras serão ignorados nas operações normais do Git.

---

## ⚠️ Considerações

- O `.gitignore` não protege arquivos já rastreados.
- Remover arquivos do versionamento não limpa o histórico.
- Secret Scanning e Push Protection possuem limitações quanto aos padrões reconhecidos.
- Credenciais reais expostas devem ser revogadas imediatamente.
- Nenhuma dessas ferramentas substitui um gerenciador de segredos.

---

## 📚 Referências

- [GitHub — Secret Scanning](https://docs.github.com/en/code-security/concepts/secret-security/secret-scanning)
- [GitHub — Push Protection](https://docs.github.com/en/code-security/concepts/secret-security/push-protection)
- [GitHub — Padrões de credenciais suportados](https://docs.github.com/en/code-security/reference/secret-security/supported-secret-scanning-patterns)
- [GitLab — Secret Push Protection](https://docs.gitlab.com/user/application_security/secret_detection/secret_push_protection/)
- [GitLab — Pipeline Secret Detection](https://docs.gitlab.com/user/application_security/secret_detection/pipeline/)
- [Git — Gitignore](https://git-scm.com/docs/gitignore)

---

[Voltar ao README](README.md)