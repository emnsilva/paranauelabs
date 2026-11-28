## জি — Identidade, código e legado

Este laboratório reúne boas práticas de organização, identidade digital, automação e segurança aplicadas ao GitHub e ao GitLab.

O objetivo é demonstrar como utilizar os recursos dessas plataformas para fortalecer a identidade digital, controlar a execução de automações, manter dependências atualizadas e reduzir o risco de exposição de informações sensíveis.

O laboratório complementa o artigo **Identidade, código e legado**, publicado no Medium, disponibilizando os procedimentos de implementação, validação e arquivos de configuração.

---

## 🎯 Princípios e Padrões

Este laboratório adota boas práticas de engenharia de plataformas:

- **Identidade Digital:** Autenticação via SSH e assinatura digital de commits via GPG, fortalecendo a autenticidade e a integridade das contribuições.
- **Privacidade:** Utilização de endereços privados de e-mail para evitar a exposição de informações pessoais nos commits.
- **Automação Consciente:** Controle dos gatilhos de execução de workflows e pipelines, considerando o contexto e o consumo de recursos computacionais.
- **Gestão de Dependências:** Monitoramento de vulnerabilidades conhecidas e automação das propostas de atualização de dependências.
- **Defense in Depth:** Adoção de camadas complementares de proteção contra o versionamento e a exposição acidental de credenciais.
- **Documentação Viva:** Procedimentos técnicos e arquivos de configuração versionados, permitindo sua manutenção e evolução.

---

## 📂 Estrutura do repositório

```text
paranauelabs/
└── identidade-codigo-legado/
    ├── README.md
    ├── 01-identidade.md
    ├── 02-automação.md
    ├── 03-segurança.md
    └── exemplos/
        ├── github-actions.yml
        ├── gitlab-ci.yml
        ├── dependabot.yml
        ├── gitlab-dependency-scanning.yml
        ├── renovate.json
        ├── gitlab-ci-security.yml
        ├── gitlab-ci-security-ultimate.yml
        └── gitignore.example
```

---

## 📚 Documentação

| Guia | Conteúdo |
|---|---|
| [Minha identidade, minha assinatura](01-identidade.md) | Proteção do e-mail pessoal, autenticação SSH e assinatura GPG. |
| [No controle do próprio ritmo](02-automacao.md) | GitHub Actions, GitLab CI/CD, Dependabot, Dependency Scanning e Renovate. |
| [Protegendo o que construímos](03-seguranca.md) | Secret Scanning, Secret Detection, Push Protection e `.gitignore`. |

### README de perfil

O GitHub e o GitLab permitem personalizar o perfil por meio de um README.

Crie um repositório público no seu namespace pessoal, com o mesmo nome do seu usuário, e adicione um arquivo `README.md` na raiz.

No GitLab, o slug do projeto deve corresponder exatamente ao nome do usuário.

Documentação oficial: [GitHub](https://docs.github.com/en/account-and-profile/how-tos/profile-customization/managing-your-profile-readme) | [GitLab](https://docs.gitlab.com/user/profile/#add-details-to-your-profile-with-a-readme).

---

## ⚙️ Arquitetura de CI/CD

Os exemplos de automação foram desenhados para execução manual, permitindo controlar o consumo de runners durante as atividades de experimentação.

- **GitHub Actions:** Workflows acionados exclusivamente via `workflow_dispatch`.
- **GitLab CI/CD:** Pipelines criados pela interface, utilizando `workflow: rules`.
- **Dependabot:** Monitoramento de vulnerabilidades e propostas de atualização de dependências.
- **Renovate:** Automação de propostas de atualização de dependências no GitLab.
- **Dependency Scanning:** Identificação de vulnerabilidades conhecidas em dependências suportadas.

A execução manual é uma escolha para o contexto deste laboratório, não uma recomendação universal para ambientes produtivos.

As análises de segurança integradas aos pipelines manuais dependem do seu acionamento. O Dependabot e o Renovate possuem mecanismos próprios de execução.

---

## 📐 Diagramas de Arquitetura

### 1. Identidade Digital

```text
[ Ambiente Local ]
        |
        +-- SSH --------> Autenticação
        |
        +-- GPG --------> Assinatura digital
        |
        +-- Email ------> Privacidade
        |
        v
[ GitHub / GitLab ]
        |
        +-- Verificação de acesso
        +-- Verificação de assinatura
```

### 2. Controle de Automação

```text
[ GitHub ]                     [ GitLab ]
     |                              |
workflow_dispatch              workflow: rules
     |                              |
GitHub Actions                 GitLab CI/CD
     |                              |
     v                              v
  Runner                         Runner
     |                              |
     +---------- Jobs --------------+
                  |
                  v
           Logs e resultados
```

### 3. Camadas de Proteção

```text
[ Ambiente Local ]
        |
        | .gitignore
        | Evita inclusão acidental de arquivos
        v
[ Commit ]
        |
        | Assinatura GPG
        | Autenticidade e integridade
        v
[ Push ]
        |
        | Push Protection
        | Bloqueio de credenciais reconhecidas
        v
[ Repositório Remoto ]
        |
        +-- Secret Scanning / Secret Detection
        +-- Validity Checks (quando disponíveis)
        +-- Análise de dependências
```

A disponibilidade das camadas depende da plataforma, do plano contratado e das configurações do repositório.

---

## 🔐 Segurança

- **SSH:** Autenticação baseada em chaves Ed25519.
- **GPG:** Assinatura digital de commits e verificação de integridade.
- **E-mail privado:** Preservação do endereço de e-mail pessoal.
- **Secret Scanning / Secret Detection:** Identificação de possíveis credenciais expostas.
- **Push Protection:** Bloqueio preventivo de credenciais reconhecidas.
- **Validity Checks:** Verificação da validade de credenciais suportadas.
- **Gitignore:** Exclusão de arquivos não rastreados que não devem ser versionados.

Nenhuma dessas ferramentas substitui um gerenciador de segredos ou oferece proteção absoluta contra vazamentos.

---

## 🧰 Pré-requisitos
- Linux com Bash.
- Git, OpenSSH e GnuPG instalados.
- Contas no GitHub e/ou GitLab.
- Repositório de testes previamente clonado, com commit inicial e branch remota configurada.
- Runners disponíveis para os exemplos de CI/CD.
- Docker para a execução local do Renovate.
- Permissões necessárias para configurar os recursos do repositório.

Verifique as ferramentas instaladas:

```bash
git --version
ssh -V
gpg --version
docker --version
```

O Docker é necessário apenas para a opção de execução local do Renovate.

---

## 🚀 Como utilizar
1. Clone o repositório.
2. Acesse a pasta `identidade-codigo-legado/`.
3. Consulte o guia correspondente à funcionalidade desejada.
4. Adapte os arquivos de configuração ao seu projeto.
5. Execute os procedimentos em um repositório de testes.
6. Valide os resultados antes de aplicar as configurações em outros ambientes.

Os arquivos da pasta `examples/` são modelos de configuração e não são executados automaticamente pelo Paranauê Labs.

### Arquivos de configuração
| Arquivo | Destino no repositório de testes |
|---|---|
| [github-actions.yml](examples/github-actions.yml) | `.github/workflows/lab.yml` |
| [gitlab-ci.yml](examples/gitlab-ci.yml) | `.gitlab-ci.yml` |
| [dependabot.yml](examples/dependabot.yml) | `.github/dependabot.yml` |
| [gitlab-dependency-scanning.yml](examples/gitlab-dependency-scanning.yml) | Incorporar ao `.gitlab-ci.yml` |
| [renovate.json](examples/renovate.json) | `renovate.json` |
| [gitlab-ci-security.yml](examples/gitlab-ci-security.yml) | `.gitlab-ci.yml` com Secret Detection |
| [gitlab-ci-security-ultimate.yml](examples/gitlab-ci-security-ultimate.yml) | `.gitlab-ci.yml` com Secret Detection e Dependency Scanning |
| [gitignore.example](examples/gitignore.example) | `.gitignore` |

Preserve as configurações existentes no projeto. Os exemplos completos de pipelines do GitLab são alternativas e não devem ser concatenados.

Execute os comandos dos guias por etapas e nunca compartilhe credenciais reais, chaves privadas ou passphrases.

---

## 🔗 Referências
- [Paranauê Labs — GitHub](https://github.com/emnsilva)
- [Paranauê Labs — GitLab](https://gitlab.com/emnsilva)
- [Git Documentation](https://git-scm.com/doc)
- [GitHub Documentation](https://docs.github.com/)
- [GitLab Documentation](https://docs.gitlab.com/)
- [Renovate Documentation](https://docs.renovatebot.com/)