# Arquitetura — O Vigia do K8s

> Documentação técnica de engenharia do agente autônomo de remediação efêmera para Kubernetes.

---

## 1. Visão Geral

O Vigia é um agente de remediação efêmera que opera no limite entre observabilidade e orquestração. Ele não substitui um SRE — ele acelera o ciclo de detecção-diagnóstico-ação para problemas crônicos e bem compreendidos, mantendo o humano no centro da decisão.

### 1.1 Princípios de Design

| Princípio | Implementação |
|-----------|---------------|
| **Human-in-the-Loop como padrão** | Modo `approval` é o default; `auto` requer explícita ativação |
| **Ações reversíveis** | Whitelist limitada a `rollout restart`, `delete pod`, `patch` — nada destrutivo |
| **Observabilidade completa** | Todo diagnóstico, proposta e execução é logado com contexto completo |
| **Fail-closed** | Se o LLM não reconhece o padrão, o agente **sempre** escala para humano |
| **Zero credenciais no código** | Todas as configurações via `.env` (não versionado) |

### 1.2 Escopo Deliberado

O Vigia **não** faz:
- Escalar recursos automaticamente (HPA/VPA já fazem isso)
- Modificar configurações de rede ou segurança
- Agir em namespaces de produção sem dupla aprovação
- Substituir runbooks manuais para incidentes novos ou complexos

O Vigia **faz**:
- Detectar pods em `CrashLoopBackOff`, `ImagePullBackOff`, `OOMKilled`, `Evicted`
- Coletar evidências (`describe`, logs, events) em formato estruturado
- Classificar a causa via LLM com runbooks embarcados (RAG)
- Propor ação com nível de confiança e risco estimado
- Executar ação aprovada e reportar resultado

---

## 2. Diagrama de Componentes

```
┌─────────────────────────────────────────────────────────────────────────┐
│                              Host / VM                                  │
│                                                                         │
│  ┌─────────────────────┐         ┌────────────────────────────────────┐ │
│  │   Ollama Service    │         │           Vigia Agent              │ │
│  │  ┌───────────────┐  │         │  ┌─────────┐  ┌─────────┐          │ │
│  │  │  LLM Engine   │  │◄────────│  │  Agent  │  │  K8s    │          │ │
│  │  │  (llama3.2)   │  │  HTTP   │  │  Core   │──│ Client  │          │ │
│  │  └───────────────┘  │         │  └────┬────┘  └────┬────┘          │ │
│  │       :11434        │         │       │            │               │ │
│  └─────────────────────┘         │  ┌────┴────┐  ┌────┴────┐          │ │
│                                  │  │  LLM    │  │  K8s    │          │ │
│                                  │  │ Client  │  │ Cluster │          │ │
│                                  │  └─────────┘  └─────────┘          │ │
│                                  │       │                            │ │
│                                  │  ┌────┴────┐                       │ │
│                                  │  │ Notifier│◄──────────────────┐   │ │
│                                  │  │         │                   │   │ │
│                                  │  └─────────┘                   │   │ │
│                                  └────────────────────────────────│───┘ │
│                                                                   │     │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  Volumes:                                                       │    │
│  │  • ollama-models  → /root/.ollama (persiste downloads)          │    │
│  │  • ~/.kube        → /root/.kube (acesso ao cluster)             │    │
│  │  • ./logs         → /app/logs (audit trail)                     │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ kubectl API
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                         Kubernetes Cluster                              │
│                                                                         │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  ┌────────────┐   │
│  │ Pod Failing  │  │   Events     │  │   Metrics    │  │ ServiceAcc │   │
│  │ (describe)   │  │ (kubectl)    │  │ (optional)   │  │ (RBAC)     │   │
│  └──────────────┘  └──────────────┘  └──────────────┘  └────────────┘   │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                                    │ Webhook
                                    ▼
┌─────────────────────────────────────────────────────────────────────────┐
│                      Plataforma de Notificação                          │
│                                                                         │
│  ┌─────────────────────────────────────────────────────────────────┐    │
│  │  📬 Slack Message                                               │    │
│  │  ─────────────────────────────────────────────────────────────  │    │
│  │  🚨 Pod `payments-api-7d9f4b8c5-x2k9m` em CrashLoopBackOff      │    │
│  │                                                                 │    │
│  │  Diagnóstico: OOMKilled — memory limit insuficiente             │    │
│  │  Ação proposta: Rollout restart com limit de memória ajustado   │    │
│  │  Confiança: 0.92 | Risco: baixo                                 │    │
│  │                                                                 │    │
│  │  [✅ Aprovar]  [❌ Rejeitar]  [⬆️ Escalar]                      │    │
│  │                                                                 │    │
│  │  ⏳ Expira em 15 minutos                                        │    │
│  └─────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

## 3. Fluxo de Execução Detalhado

### 3.1 Diagrama de Sequência

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  Timer  │    │  Agent  │    │ K8s API │    │   LLM   │    │  Slack  │
└────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘    └────┬────┘
     │              │              │              │              │
     │  trigger     │              │              │              │
     │─────────────►│              │              │              │
     │              │              │              │              │
     │              │ list pods    │              │              │
     │              │ with status  │              │              │
     │              │─────────────►│              │              │
     │              │              │              │              │
     │              │ pod list     │              │              │
     │              │◄─────────────│              │              │
     │              │              │              │              │
     │              │ [pod failing]│              │              │
     │              │              │              │              │
     │              │ describe pod │              │              │
     │              │ get logs     │              │              │
     │              │ get events   │              │              │
     │              │─────────────►│              │              │
     │              │              │              │              │
     │              │ evidence     │              │              │
     │              │◄─────────────│              │              │
     │              │              │              │              │
     │              │ prompt +     │              │              │
     │              │ runbooks     │              │              │
     │              │─────────────►│              │              │
     │              │              │              │              │
     │              │ diagnosis    │              │              │
     │              │◄─────────────│              │              │
     │              │              │              │              │
     │              │ [mode=dry-run]              │              │
     │              │ → log only                  │              │
     │              │              │              │              │
     │              │ [mode=approval]             │              │
     │              │ → send proposal             │              │
     │              │───────────────────────────────────────────►│
     │              │              │              │              │
     │              │              │              │              │ click
     │              │              │              │              │◄───────
     │              │              │              │              │
     │              │◄───────────────────────────────────────────│
     │              │  approval/rejection/timeout                │
     │              │                │              │            │
     │              │ [approved]     │              │            │
     │              │ execute action │              │            │
     │              │───────────────►│              │            │
     │              │                │              │            │
     │              │ result         │              │            │
     │              │◄───────────────│              │            │
     │              │                │              │            │
     │              │ notify result  │              │            │
     │              │───────────────────────────────────────────►│
     │              │                │              │            │
```

### 3.2 Estados do Incidente

```
                    ┌─────────────┐
         ┌─────────►│  DETECTED   │◄────────┐
         │          └──────┬──────┘         │
         │                 │ collect        │
         │                 ▼                │
         │          ┌─────────────┐         │
         │          │ COLLECTING  │         │
         │          └──────┬──────┘         │
         │                 │ analyze        │
         │                 ▼                │
         │          ┌─────────────┐         │
         │          │  ANALYZING  │         │
         │          └──────┬──────┘         │
         │                 │ classify       │
         │                 ▼                │
         │          ┌─────────────┐         │
         │     ┌───►│  PROPOSING  │         │
         │     │    └──────┬──────┘         │
         │     │           │ mode?          │
         │     │           ▼                │
         │     │    ┌─────────────┐         │
         │     └───►│  DRY-RUN    │         │
         │          │  (logged)   │         │
         │          └──────┬──────┘         │
         │                 │                │
         │                 ▼                │
         │          ┌─────────────┐         │
         │     ┌───►│  WAITING    │         │
         │     │    │  APPROVAL   │         │
         │     │    └──────┬──────┘         │
         │     │           │ response?      │
         │     │           ▼                │
         │     │    ┌─────────────┐         │
         │     └───►│  APPROVED   │         │
         │          └──────┬──────┘         │
         │                 │ execute        │
         │                 ▼                │
         │          ┌─────────────┐         │
         │          │  EXECUTING  │         │
         │          └──────┬──────┘         │
         │                 │ result         │
         │                 ▼                │
         │          ┌─────────────┐         │
         └─────────►│  RESOLVED   │         │
                    │  or FAILED  │─────────┘
                    └─────────────┘
```

---

## 4. Contratos Internos

### 4.1 Estrutura do Diagnóstico LLM

O LLM retorna um JSON estruturado que o agente valida antes de prosseguir:

```json
{
  "incident_id": "uuid-v4",
  "timestamp": "2026-07-07T14:32:01Z",
  "pod": {
    "name": "payments-api-7d9f4b8c5-x2k9m",
    "namespace": "payments",
    "status": "CrashLoopBackOff",
    "restarts": 5
  },
  "diagnosis": {
    "symptom": "Container reinicia a cada 2 minutos",
    "root_cause": "OOMKilled — container excede memory limit de 256Mi",
    "evidence": [
      "Last State: Terminated, Reason: OOMKilled, Exit Code: 137",
      "Memory Usage: 312Mi / Limit: 256Mi (metrics)",
      "Log snippet: 'MemoryError: Unable to allocate 512 MiB'"
    ]
  },
  "action": {
    "type": "rollout_restart",
    "target": "deployment/payments-api",
    "parameters": {
      "memory_limit": "512Mi"
    },
    "rationale": "Aumentar memory limit para acomodar pico de uso"
  },
  "confidence": 0.92,
  "risk": "low",
  "requires_approval": true,
  "runbook_match": "OOMKilled-memory-limit"
}
```

### 4.2 Protocolo de Aprovação

A mensagem enviada ao Slack contém um `callback_id` que o agente usa para correlacionar resposta com incidente:

```json
{
  "callback_id": "vigia-incident-uuid-v4",
  "actions": [
    {
      "name": "approve",
      "value": "approved",
      "style": "primary"
    },
    {
      "name": "reject",
      "value": "rejected",
      "style": "danger"
    },
    {
      "name": "escalate",
      "value": "escalated"
    }
  ],
  "expiration": "2026-07-07T14:47:01Z"
}
```

**Timeout**: 15 minutos. Sem resposta, o incidente é marcado como `EXPIRED` e escalado automaticamente.

### 4.3 Log de Auditoria

Cada ação gera um registro imutável em `./logs/audit-YYYY-MM-DD.jsonl`:

```json
{
  "timestamp": "2026-07-07T14:35:22Z",
  "incident_id": "uuid-v4",
  "event": "action_executed",
  "actor": "vigia-agent",
  "approved_by": "slack:user-U12345678",
  "action": {
    "type": "rollout_restart",
    "target": "deployment/payments-api",
    "command": "kubectl rollout restart deployment/payments-api -n payments"
  },
  "result": {
    "status": "success",
    "output": "deployment.apps/payments-api restarted",
    "duration_ms": 2341
  },
  "context": {
    "mode": "approval",
    "confidence": 0.92,
    "risk": "low",
    "runbook": "OOMKilled-memory-limit"
  }
}
```

---

## 5. Decisões Arquiteturais (ADRs)

### ADR-001: LLM Local vs. API Paga

**Contexto**: Precisávamos de um motor de inferência para diagnóstico. Opções: OpenAI API (GPT-4), Claude API, ou modelos locais via Ollama.

**Decisão**: Suporte a ambos, com Ollama local como padrão.

**Razões**:
- **Custo zero** para labs e PoCs
- **Privacidade** — dados do cluster não saem da VM
- **Latência** — sem roundtrip de rede
- **Offline** — funciona sem internet após download do modelo

**Trade-offs**:
- Qualidade de diagnóstico pode ser inferior a GPT-4 para casos complexos
- Requer mais RAM/CPU na VM (4–8 GB para modelos 3B–7B)
- Modelos menores (3B) têm maior taxa de alucinação; mitigado por runbooks estruturados (RAG)

**Status**: Aceito. Revisar se escalar para produção com incidentes críticos.

---

### ADR-002: Human-in-the-Loop como Padrão

**Contexto**: Agentes autônomos em infraestrutura carregam risco de ações irreversíveis. Decidir entre execução totalmente automática, semi-automática ou manual.

**Decisão**: Modo `approval` é o padrão. `auto` requer explícita ativação e só executa ações de `risk=low` na whitelist.

**Razões**:
- **Confiança gradual** — o time ganha confiança no agente antes de delegar
- **Accountability** — sempre há um humano responsável pela ação executada
- **Compliance** — auditorias exigem rastreabilidade de quem aprovou

**Trade-offs**:
- Latência de resolução aumenta (espera por aprovação)
- Requer disponibilidade do time para responder notificações
- Modo `auto` em dev/homolog compensa a latência em produção

**Status**: Aceito. Não há plano de remover HiL para produção.

---

### ADR-003: Docker Compose vs. Kubernetes-native

**Contexto**: O agente precisa rodar próximo ao cluster. Opções: deployment no próprio K8s, systemd service na VM, ou Docker Compose.

**Decisão**: Docker Compose na VM do host, não no cluster.

**Razões**:
- **Separação de responsabilidades** — o agente é um cliente do cluster, não um componente interno
- **Facilidade de teardown** — `docker compose down -v` limpa tudo
- **Independência do cluster** — se o cluster cai, o agente ainda notifica
- **Simplicidade** — não precisa de Helm chart, RBAC interno, ou admission controllers

**Trade-offs**:
- Single point of failure (a VM)
- Não escala horizontalmente nativamente
- Requer acesso de rede ao cluster (kubeconfig exposto via bind mount)

**Status**: Aceito para lab. Para produção, avaliar deployment no cluster com ServiceAccount dedicada.

---

### ADR-004: Python vs. Go

**Contexto**: A stack de IA/LLM é dominada por Python (LangChain, OpenAI SDK, Kubernetes client). Go oferece melhor performance e binário único.

**Decisão**: Python para o agente, Go reservado para futuro operador Kubernetes nativo.

**Razões**:
- **Ecossistema** — LangChain, Pydantic, e integrações de chat (Slack SDK) são mature em Python
- **Prototipação** — iteração rápida para validar conceito
- **Time-to-market** — MVP funcional em dias, não semanas

**Trade-offs**:
- Overhead de runtime (Python + venv + containers)
- Cold start mais lento que binário Go
- Menor controle de memória para long-running processes

**Status**: Aceito. Reescrever core em Go se escalar para operador K8s nativo.

---

## 6. Matriz de Risco de Ações

| Ação | Risco | Modo Auto | Requer Aprovação | Reversível | Runbook |
|------|-------|-----------|------------------|------------|---------|
| `rollout restart deployment` | Baixo | ✅ Sim | Não (auto) | ✅ Sim | `deployment-restart` |
| `delete pod` | Baixo | ✅ Sim | Não (auto) | ✅ Sim | `pod-delete-evicted` |
| `patch deployment` (resources) | Médio | ❌ Não | ✅ Sim | ✅ Sim | `resource-adjust` |
| `scale deployment` (replicas) | Médio | ❌ Não | ✅ Sim | ✅ Sim | `scale-up` |
| `kubectl exec` (debug) | Alto | ❌ Não | ✅ Sim | N/A | `debug-exec` |
| Modificar ConfigMap/Secret | Alto | ❌ Não | ✅ Sim | ❌ Não | N/A (escalar) |
| Alterar NetworkPolicy | Alto | ❌ Não | ✅ Sim | ❌ Não | N/A (escalar) |
| `delete namespace` | Crítico | ❌ Não | ✅ Dupla | ❌ Não | N/A (escalar) |

---

## 7. Especificação Técnica

### 7.1 Requisitos de Hardware

| Perfil | CPU | RAM | Disco | Uso |
|--------|-----|-----|-------|-----|
| **Mínimo** | 2 cores | 4 GB | 20 GB | Llama 3.2 3B, 1 namespace |
| **Recomendado** | 4 cores | 8 GB | 40 GB | DeepSeek R1 7B, múltiplos namespaces |
| **Produção** | 4 cores | 16 GB | 100 GB | Modelo 13B+, retention de logs 30 dias |

### 7.2 Dependências de Rede

| Origem | Destino | Porta | Protocolo | Descrição |
|--------|---------|-------|-----------|-----------|
| Vigia | Ollama | 11434 | HTTP | Inferência LLM |
| Vigia | K8s API | 6443 | HTTPS | kubectl / API server |
| Vigia | Slack API | 443 | HTTPS | Notificações e webhooks |
| Host | Ollama | 11434 | HTTP | Acesso direto (opcional) |

### 7.3 Retenção de Dados

| Tipo | Retenção | Armazenamento |
|------|----------|---------------|
| Logs de auditoria | 30 dias | `./logs/` (bind mount) |
| Modelos Ollama | Persistente | Docker volume `ollama-models` |
| Cache de diagnósticos | 7 dias | Memória (LRU) |
| Mensagens Slack | 24 horas | N/A (ephemeral) |

---

## 8. Roadmap Técnico

### Fase 1 — MVP (Atual)
- [x] Monitoramento de pods com status de falha
- [x] Coleta de `describe`, logs e events
- [x] Diagnóstico via LLM com runbooks JSON
- [x] Notificação Slack com botões de aprovação
- [x] Execução de ações whitelist (restart, delete pod)
- [x] Log de auditoria em JSONL

### Fase 2 — Robustez
- [ ] RAG com vector database para runbooks (ChromaDB ou similar)
- [ ] Suporte a múltiplos LLMs simultâneos (ensemble de diagnóstico)
- [ ] Métricas Prometheus do agente (latência, taxa de aprovação)
- [ ] Dashboard web com histórico de incidentes (Streamlit ou FastAPI)
- [ ] Modo "auto" com aprendizado por reforço (aprovado X vezes → executa sozinho)

### Fase 3 — Produção
- [ ] Operador Kubernetes nativo (CRD + controller em Go)
- [ ] mTLS entre agente e Ollama
- [ ] Vault integration para segredos (HashiCorp Vault ou AWS Secrets Manager)
- [ ] Policy-as-code para ações (OPA/Rego)
- [ ] Testes de caos automatizados para validar resiliência

---

## 9. Referências

- [Kubernetes API Concepts](https://kubernetes.io/docs/reference/using-api/)
- [LangChain Documentation](https://python.langchain.com/docs/)
- [Ollama REST API](https://github.com/ollama/ollama/blob/main/docs/api.md)
- [Slack Block Kit](https://api.slack.com/block-kit)
- [OpenAI API Reference](https://platform.openai.com/docs/api-reference)

---

*Documento versionado. Revisão: 2026-07-07*
*Próxima revisão programada: após conclusão da Fase 2*
