# O Vigia do K8s

Laboratório de agente autônomo de remediação efêmera para Kubernetes

Esse lab é um ambiente de estudo e experimentação para construir um agente de IA especializado em manter a saúde de clusters Kubernetes. O projeto monitora pods em falha, diagnostica a causa raiz via LLM e propõe ações de remediação — sempre com supervisão humana ou execução automática controlada.

## O que é o Vigia do K8s?

O **Vigia do K8s** foi criado para quem quer entender na prática como um agente de IA pode operar infraestrutura de forma segura e auditável. Em vez de um script genérico de monitoramento, o repositório trata a remediação como um sistema de aprendizado: cada componente isola uma responsabilidade — coleta, diagnóstico, decisão e execução.

A filosofia do projeto é simples: **o agente propõe, o humano aprova**. Variáveis sensíveis ficam em arquivos `.env` locais (não versionados). Ações destrutivas nunca executam sem autorização explícita, exceto em modo `dry-run` ou `auto` com whitelist restrita. Os exemplos usam recursos mínimos e ações reversíveis, pensados para labs — fáceis de subir e destruir sem impacto.

Seja para comparar LLMs locais com APIs pagas, testar notificações no Slack ou configurar um pipeline de remediação com Human-in-the-Loop, este repositório oferece uma base consistente e documentada para experimentação com agentes de IA em infraestrutura.

## Funcionalidades

- **Monitoramento contínuo**: Observa namespaces em busca de pods em estado de falha (CrashLoopBackOff, ImagePullBackOff, OOMKilled, etc).
- **Diagnóstico por IA**: Usa LLM local (Ollama) ou OpenAI para analisar `kubectl describe`, logs e events do cluster.
- **Human-in-the-Loop**: Propõe ação no Slack/Teams/WhatsApp e aguarda clique em "Aprovar" antes de executar.
- **Execução automática controlada**: Modo `auto` executa ações de baixo risco automaticamente quando a confiança do LLM é alta.
- **Runbooks embutidos**: Whitelist de ações permitidas em `config/runbooks.json` — fora da lista, o agente sempre escala para humano.
- **Audit trail completo**: Todo diagnóstico, proposta e ação é logado em `./logs/` com timestamp e quem aprovou.
- **100% containerizado**: Ollama e Vigia sobem com `docker compose up -d`.
- **Zero custo de API**: Roda com modelos locais (Llama, Qwen, DeepSeek) sem depender de serviços pagos.

## Visão geral da arquitetura

O repositório segue uma estrutura em camadas por responsabilidade:

```
infra/         → Scripts de preparação da VM (setup e uninstall)
src/           → Código-fonte do agente (coleta, diagnóstico, notificação)
config/        → Runbooks e regras de remediação
```

### Diagrama de fluxo

```
[Cluster K8s] ──> [Pod em Falha]
        │
        ├──> kubectl describe + logs + events
        │
        ├──> [Vigia] ──> Análise LLM
        │                    │
        │                    ├──> Modo dry-run: só loga
        │                    ├──> Modo approval: notifica e aguarda
        │                    └──> Modo auto: executa se risco=baixo
        │
        └──> [Slack/Teams] ──> [Aprovar] [Rejeitar] [Escalar]
                                    │
                                    └──> kubectl rollout restart / delete pod
```

### Estrutura de diretórios

```
02-o-vigia-do-k8s/
├── README.md                 # Este arquivo
├── docker-compose.yml        # Ollama + Vigia
├── Dockerfile                # Imagem do agente
├── requirements.txt          # Dependências Python
├── vigia.py                  # Entrypoint
├── .env.example              # Template de configuração
├── config/
│   └── runbooks.json         # Ações permitidas e regras de diagnóstico
├── src/
│   ├── __init__.py
│   ├── agent.py              # Loop principal do agente
│   ├── k8s_client.py         # Interação com Kubernetes
│   ├── llm_client.py         # Prompts e chamadas ao LLM
│   ├── notifier.py           # Slack/Teams/WhatsApp
│   └── utils.py              # Helpers e formatadores
├── infra/
│   ├── setup.sh              # Prepara a VM (Docker, kubectl, minikube, venv)
│   └── uninstall.sh          # Limpa a VM completamente
├── tests/
│   └── test_agent.py
└── docs/
    └── arquitetura.md        # Documentação técnica completa
```

## Início rápido

### Pré-requisitos

| Ferramenta | Versão mínima | Uso |
|---|---|---|
| [Docker](https://docs.docker.com/engine/install/) | 20.10+ | Containerização do Ollama e Vigia |
| [Docker Compose](https://docs.docker.com/compose/install/) | 2.x+ | Orquestração dos serviços |
| [kubectl](https://kubernetes.io/docs/tasks/tools/) | 1.28+ | Interação com o cluster |
| [minikube](https://minikube.sigs.k8s.io/docs/start/) | 1.32+ | Cluster local para testes |
| Python (na VM) | 3.10+ | Execução do agente (fora do container) |

### 1. Prepara a VM

```bash
cd 02-o-vigia-do-k8s

# Prepara o ambiente (Docker, kubectl, minikube, venv)
sudo ./infra/setup.sh
# A VM reiniciará automaticamente em 10 segundos
```

### 2. Configura o ambiente

```bash
# Copie o template de configuração
cp .env.example .env

# Edite com seu editor preferido
nano .env
```

### 3. Sobe os serviços

```bash
# Ollama + Vigia
docker compose up -d

# Baixa o modelo (primeira vez apenas)
docker compose exec ollama ollama pull llama3.2:3b

# Acompanha os logs
docker compose logs -f vigia
```

### 4. Testa o diagnóstico

```bash
# Cria um pod propositalmente quebrado para teste
kubectl run test-crash --image=busybox --restart=Never -- /bin/false

# O Vigia deve detectar, diagnosticar e notificar no Slack
# (no modo approval, aguarda seu clique em "Aprovar")
```

## Configuração

**Nunca commite credenciais reais.** Toda configuração sensível fica no arquivo `.env` local, não versionado.

### Variáveis do agente

| Variável | Descrição | Obrigatória |
|---|---|---|
| `AI_BASE_URL` | URL do endpoint LLM (Ollama local ou OpenAI) | Sim |
| `AI_API_KEY` | Chave de API (deixe vazio para Ollama local) | Sim |
| `MODEL_NAME` | Nome do modelo (ex: `llama3.2:3b`, `gpt-4o-mini`) | Sim |
| `OLLAMA_HOST_PORT` | Porta exposta do Ollama no host (padrão: 11434) | Não |
| `MONITOR_NAMESPACES` | Namespace(s) monitorado(s). Use `all` para todos | Sim |
| `OPERATION_MODE` | `dry-run`, `approval` ou `auto` | Sim |
| `NOTIFICATION_PROVIDER` | Plataforma: `slack`, `teams` ou `whatsapp` | Sim |
| `SLACK_BOT_TOKEN` | Token do bot Slack (xoxb-...) | Se provider=slack |
| `SLACK_CHANNEL` | Canal de destino (ex: `#alertas-k8s`) | Se provider=slack |

### Modos de operação

| Modo | Descrição | Quando usar |
|---|---|---|
| `dry-run` | Só diagnostica e notifica. Nunca executa ação no cluster. | Primeiras semanas, validação de diagnósticos |
| `approval` | Propõe ação e aguarda clique em "Aprovar" no Slack/Teams. | **Padrão em produção** |
| `auto` | Executa automaticamente se confiança > 0.85 e risco=baixo. | Dev / Homolog |

> No modo `approval`, o agente envia uma mensagem interativa com botões. Se não houver resposta em 15 minutos, a ação expira e o incidente é escalado.

## Componentes

### Ollama (motor de IA)

Roda em um container dedicado com volume persistente para modelos. Acessível pelo Vigia via rede interna do Docker Compose (`http://ollama:11434`).

**Modelos recomendados:**

| Modelo | Tamanho | Uso | RAM mínima |
|---|---|---|---|
| `llama3.2:3b` | 3B | Diagnóstico rápido, pouco recurso | 4 GB |
| `qwen2.5:3b` | 3B | Alternativa ao Llama, boa em instruções | 4 GB |
| `deepseek-r1:7b` | 7B | Raciocínio mais profundo, exige mais recurso | 8 GB |
| `gpt-4o-mini` | — | Via API OpenAI, zero infra local | — |

### Vigia (agente)

Container Python com `kubectl` embutido. Monta o `~/.kube` do host para acessar o cluster. Executa o loop de monitoramento a cada N segundos (configurável).

### Kubernetes (alvo)

Pode ser um cluster minikube local, EKS, GKE, AKS ou qualquer cluster com kubeconfig acessível. O agente usa RBAC mínimo: `get`, `list`, `delete` (pods) e `patch` (deployments).

## Notificações

O agente suporta três plataformas de notificação. Configure apenas uma no `.env`.

### Slack

Requer um bot com permissões `chat:write` e `chat:write.public`. O token começa com `xoxb-`.

A mensagem enviada inclui:
- Nome do pod e namespace
- Diagnóstico resumido
- Ação proposta
- Botões: **Aprovar**, **Rejeitar**, **Escalar**

### Teams

Usa webhook de canal (Incoming Webhook). A mensagem é enviada como card adaptativo com botões de ação.

### WhatsApp

Compatível com Evolution API, Z-API ou similares. Requer `WHATSAPP_WEBHOOK_URL`, `WHATSAPP_INSTANCE` e `WHATSAPP_NUMBER`.

## Segurança

- **Sem credenciais no repositório**: `.gitignore` exclui `.env` e arquivos de log.
- **Human-in-the-Loop**: Ações só executam com aprovação explícita (modo padrão).
- **Whitelist de ações**: O agente só propõe ações listadas em `config/runbooks.json`. Fora da lista, sempre escala.
- **RBAC mínimo**: ServiceAccount dedicada sem `cluster-admin`. Máximo de `get`, `list`, `delete` (pods) e `patch` (deployments).
- **Rate limiting**: Máximo 1 ação por minuto por namespace, com cooldown de 5 minutos entre ações no mesmo deployment.
- **Audit trail**: Todo evento é logado em `./logs/` com timestamp, contexto completo e quem aprovou.
- **Labs destrutíveis**: Ações são reversíveis (restart de deployment, delete de pod). Nunca altera configurações críticas do cluster.

## Comparando os modos

| Aspecto | dry-run | approval | auto |
|---|---|---|---|
| Diagnóstico | Sim | Sim | Sim |
| Notificação | Sim | Sim | Sim |
| Execução | Nunca | Após aprovação humana | Automática (baixo risco) |
| Risco | Zero | Baixo (com supervisão) | Médio (whitelist) |
| Uso recomendado | Validação | Produção | Dev / Homolog |
| Curva de confiança | Aprendizado | Gradual | Alta |

## Perguntas frequentes

**P: Preciso de GPU para rodar o Ollama?**
Não. Os modelos recomendados (3B–7B) rodam em CPU. Uma VM com 4–8 GB de RAM é suficiente para o lab.

**P: Posso usar OpenAI em vez de Ollama?**
Sim. Altere `AI_BASE_URL` para `https://api.openai.com/v1`, preencha `AI_API_KEY` e defina `MODEL_NAME=gpt-4o-mini`. Ollama não precisa subir nesse caso.

**P: O agente funciona em produção?**
O repositório é um lab. Para produção, adicione: backend de estado para o histórico, mTLS para comunicação com Ollama, vault para segredos e testes de carga no loop de monitoramento.

**P: Como destruo tudo depois do lab?**

```bash
# Para os containers
docker compose down -v

# Ou limpa a VM inteira
sudo ./infra/uninstall.sh
# A VM reiniciará automaticamente
```

**P: O agente pode causar dano ao cluster?**
No modo `dry-run`, zero risco. No modo `approval`, só executa com seu clique. No modo `auto`, só ações da whitelist (restart de deployment, delete de pod) são executadas — todas reversíveis.

**P: Como adiciono um novo problema ao runbook?**
Edite `config/runbooks.json` e adicione o padrão de erro (regex ou substring) e a ação correspondente. Reinicie o container do Vigia para recarregar.

**P: O `minikube` é obrigatório?**
Não. Você pode apontar o agente para qualquer cluster editando o `~/.kube/config`. O minikube é apenas a forma mais simples de ter um cluster local para testes.

## Contribuindo

Contribuições são bem-vindas!

1. Mantenha exemplos mínimos e focados em aprendizado.
2. Nunca inclua credenciais, tokens ou chaves reais.
3. Documente novas variáveis no `.env.example`.
4. Teste localmente em modo `dry-run` antes de abrir um PR.

## Filosofia: laboratório vs. produção

Este repositório não pretende ser um template de produção. Ele existe para que você **experimente, compare e entenda** como um agente de IA pode operar infraestrutura de forma segura e supervisionada — do diagnóstico automático à execução com Human-in-the-Loop.

A diferença entre um lab e um ambiente real está nos detalhes: backends de estado para o histórico de incidentes, mTLS na comunicação com o LLM, vaults dedicados para segredos, testes de caos para validar resiliência, e políticas de `auto` protegidas por múltiplas aprovações. Use este projeto como ponto de partida e evolua a partir daí.

---

**Aproveitem!**
