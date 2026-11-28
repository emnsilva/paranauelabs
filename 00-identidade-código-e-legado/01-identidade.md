## 🔑 Minha identidade, minha assinatura

Este guia apresenta os procedimentos de proteção do e-mail pessoal, autenticação SSH e assinatura digital de commits com GPG no GitHub e no GitLab.

Consulte os pré-requisitos no [README.md](README.md) antes de começar.

---

## 1. Proteção do e-mail pessoal

### GitHub

1. Clique na foto do seu perfil.
2. Acesse **Settings → Emails**.
3. Habilite `Keep my email addresses private`.
4. Habilite `Block command line pushes that expose my email`.
5. Copie o endereço de e-mail `noreply` disponibilizado.

### GitLab

1. Clique na foto do seu perfil.
2. Acesse **Edit profile → Commit email**.
3. Selecione `Use a private email`.
4. Salve as alterações.
5. Copie o endereço de e-mail privado disponibilizado.

### Configuração do Git

Execute apenas o conjunto de comandos correspondente à plataforma.

```bash
# GitHub
cd /caminho/do/repositorio-github

git config --local user.name "Seu Nome"
git config --local user.email "EMAIL_NOREPLY_GITHUB"

# GitLab
cd /caminho/do/repositorio-gitlab

git config --local user.name "Seu Nome"
git config --local user.email "EMAIL_PRIVADO_GITLAB"
```

Substitua os valores pelos seus dados.

- `--global`: configura um padrão para todos os repositórios.
- `--local`: configura apenas o repositório atual e tem prioridade sobre a configuração global de mesmo nome.

Repita a configuração nos demais repositórios.

### Validação

```bash
# Verifique a identidade efetiva do autor e do committer
git var GIT_AUTHOR_IDENT
git var GIT_COMMITTER_IDENT

# Consulte os emails presentes no histórico
git log --all --format="%ae%n%ce" | sort -u
```

A identidade utilizada nos novos commits deve apresentar o endereço privado da plataforma. A alteração não modifica commits anteriores.

### Correção do último commit (opcional)

Execute somente se o último commit for de sua autoria, possuir seu e-mail pessoal e ainda não tiver sido publicado.

```bash
# Verifique se existem alterações pendentes
git status
git diff --cached

# Prossiga somente se o staging estiver vazio
git commit --amend --reset-author --no-edit

# Confira os emails após a correção
git log -1 --format="Autor: %ae%nCommitter: %ce"
```

### Teste

Utilize o repositório de testes configurado anteriormente.

```bash
# Confira se não existem alterações pendentes
git status

# Crie um commit de teste com o staging vazio
git commit --allow-empty -m "Teste de email privado"

# Confira os emails utilizados
git log -1 --format="Autor: %ae%nCommitter: %ce"

# Após validar os emails e o histórico a enviar
git push
```

**Resultado esperado:** autor e committer utilizando o endereço privado da plataforma.

> **Atenção:** o bloqueio do GitHub verifica o e-mail do autor do commit mais recente, não todo o histórico. O GitLab oferece e-mail privado, mas não possui um bloqueio equivalente nas configurações pessoais da conta.

---

## 2. Chave SSH

A chave SSH permite autenticar operações remotas, como push e pull, sem utilizar as credenciais de login da plataforma.

Neste exemplo, utilizaremos uma chave compartilhada entre GitHub e GitLab. Também é possível utilizar chaves independentes.

### Geração da chave

```bash
# Verifique se já existem chaves SSH
ls -la ~/.ssh/

# Gere uma chave Ed25519
ssh-keygen -t ed25519 -C "minha-chave-git"
```

Durante a geração:

- Aceite o caminho padrão, caso esteja disponível.
- Configure uma passphrase forte.
- Nunca sobrescreva uma chave existente.
- Caso escolha outro caminho, ajuste os comandos seguintes.

Serão gerados dois arquivos:

| Arquivo | Finalidade |
|---|---|
| `~/.ssh/id_ed25519` | Chave privada. Nunca compartilhe. |
| `~/.ssh/id_ed25519.pub` | Chave pública. Cadastre nas plataformas. |

### Configuração do SSH Agent

O SSH Agent mantém a chave disponível durante a sessão, evitando solicitar a passphrase a cada operação.

```bash
# Verifique se existe um agent disponível
ssh-add -l

# Inicie o agent somente se não houver um disponível
eval "$(ssh-agent -s)"

# Adicione a chave privada
ssh-add ~/.ssh/id_ed25519

# Confira a chave carregada
ssh-add -l
```

### Cadastro da chave pública

```bash
# Copie toda a linha exibida
cat ~/.ssh/id_ed25519.pub
```

#### GitHub

1. Acesse **Settings → SSH and GPG keys**.
2. Clique em **New SSH key**.
3. Informe um título.
4. Em `Key type`, selecione `Authentication Key`.
5. Cole a chave pública em `Key`.
6. Clique em **Add SSH key**.

#### GitLab

1. Acesse **Edit profile → Access → SSH keys**.
2. Clique em **Add new key**.
3. Cole a chave pública e informe um título.
4. Em `Usage type`, selecione `Authentication`.
5. Defina uma data de expiração.
6. Clique em **Add key**.

### Teste de autenticação

Na primeira conexão, confira o fingerprint do servidor na documentação oficial antes de aceitá-lo.

- [Fingerprints do GitHub](https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints)
- [Fingerprints do GitLab](https://docs.gitlab.com/user/gitlab_com/#ssh-host-keys-fingerprints)

```bash
# GitHub
ssh -T git@github.com

# GitLab
ssh -T git@gitlab.com
```

**Resultado esperado:** mensagem de autenticação bem-sucedida ou de boas-vindas identificando seu usuário.

O GitHub também informa que não oferece acesso a um shell interativo.

### Configuração dos repositórios

Dentro de cada repositório, copie a URL SSH disponibilizada pela respectiva plataforma.

```bash
# Verifique a configuração atual
git remote -v

# GitHub
git remote set-url origin git@github.com:usuario/repositorio.git

# OU GitLab
git remote set-url origin git@gitlab.com:usuario/repositorio.git
```

Execute apenas o comando correspondente ao repositório.

Caso o remote `origin` não exista, utilize `git remote add origin` seguido da URL SSH.

### Validação

```bash
git remote -v
git ls-remote origin
```

**Resultado esperado:** URL SSH configurada e comunicação com o repositório remoto sem erros de autenticação.

---

## 3. Chave GPG

O GPG permite assinar digitalmente commits, possibilitando a verificação da assinatura e da integridade do conteúdo.

Neste exemplo, utilizaremos uma chave GPG para cada plataforma, associada ao respectivo e-mail privado.

### Geração das chaves

```bash
# Verifique se já existem chaves
gpg --list-secret-keys --keyid-format LONG

# Gere uma chave
gpg --full-generate-key
```

Utilize as seguintes configurações:

| Parâmetro | Valor |
|---|---|
| Algoritmo | RSA and RSA |
| Tamanho | 4096 bits |
| Validade | 1y (1 ano) |
| Nome | Seu nome |
| E-mail | Endereço privado da plataforma |
| Comentário | Opcional |
| Passphrase | Senha forte |

Repita o procedimento para gerar a chave da outra plataforma.

Não utilize seu e-mail pessoal caso deseje preservar essa informação, pois os dados associados à chave pública podem ser consultados.

### Identificação das chaves

```bash
gpg --list-secret-keys --keyid-format LONG --fingerprint
```

Exemplo ilustrativo:

```text
sec   rsa4096/30F2B65B9246B6CA [SC]
      D5E4F29F3275DC0CDA8FFC8730F2B65B9246B6CA
uid   Seu Nome (email privado)
```

A sequência abaixo da linha `sec` corresponde ao fingerprint completo da chave primária.

Identifique cada chave pelo seu e-mail e copie os fingerprints reais.

### Exportação das chaves públicas

```bash
# GitHub
gpg --armor --export FINGERPRINT_GPG_GITHUB

# GitLab
gpg --armor --export FINGERPRINT_GPG_GITLAB
```

Substitua os valores pelos fingerprints copiados.

Copie separadamente o conteúdo de cada chave, incluindo:

```text
-----BEGIN PGP PUBLIC KEY BLOCK-----
...
-----END PGP PUBLIC KEY BLOCK-----
```

### Cadastro das chaves

#### GitHub

1. Acesse **Settings → SSH and GPG keys**.
2. Clique em **New GPG key**.
3. Informe um título, se solicitado.
4. Cole a chave pública correspondente ao GitHub.
5. Clique em **Add GPG key**.

#### GitLab

1. Acesse **Edit profile → Access → GPG keys**.
2. Clique em **Add new key**.
3. Cole a chave pública correspondente ao GitLab.
4. Clique em **Add key**.

### Configuração do Git

Execute dentro de cada repositório.

```bash
# Defina o formato e o programa de assinatura
git config --local gpg.format openpgp
git config --local gpg.program gpg

# GitHub
git config --local user.signingkey FINGERPRINT_GPG_GITHUB

# OU GitLab
git config --local user.signingkey FINGERPRINT_GPG_GITLAB

# Habilite a assinatura automática dos commits
git config --local commit.gpgsign true

# Configure o terminal para o GPG
export GPG_TTY="$(tty)"
```

Execute apenas o comando `user.signingkey` correspondente à plataforma.

Adicione o comando `export GPG_TTY="$(tty)"` ao `~/.bashrc`, caso utilize Bash, para tornar a configuração persistente nas sessões interativas.

### Validação

```bash
git var GIT_COMMITTER_IDENT
git config user.signingkey
git config commit.gpgsign
```

**Resultado esperado:**

- E-mail privado da plataforma.
- Fingerprint da chave correspondente.
- Assinatura automática habilitada (`true`).

### Teste

```bash
# Confira se não existem alterações pendentes
git status

# Crie um commit de teste com o staging vazio
git commit --allow-empty -m "Teste de assinatura GPG"

# Verifique a assinatura digital
git verify-commit HEAD

# Confira os emails associados ao commit
git log -1 --format="Autor: %ae%nCommitter: %ce"

# Após validar a assinatura e os emails
git push
```

Acesse o histórico de commits do GitHub ou GitLab.

**Resultado esperado:** assinatura válida localmente e selo **Verified** na plataforma.

> **Atenção:** o e-mail do committer deve corresponder a uma identidade da chave GPG reconhecida pela plataforma. Proteja suas chaves privadas, passphrases e certificados de revogação.

---

## 📚 Referências

- [GitHub — Privacidade do e-mail](https://docs.github.com/en/account-and-profile/how-tos/email-preferences)
- [GitLab — Perfil e e-mail privado](https://docs.gitlab.com/user/profile/)
- [GitHub — SSH](https://docs.github.com/en/authentication/connecting-to-github-with-ssh)
- [GitLab — SSH](https://docs.gitlab.com/user/ssh/)
- [GitHub — Assinatura de commits](https://docs.github.com/en/authentication/managing-commit-signature-verification)
- [GitLab — GPG](https://docs.gitlab.com/user/project/repository/signed_commits/gpg/)

---

[Voltar ao README](README.md)