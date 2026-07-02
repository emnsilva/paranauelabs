#!/usr/bin/env python3
# Vigia - Guarda Noturno do Kubernetes
# Fase 1: Detecta problemas, coleta evidencias e diagnostica com IA.
# Nenhuma acao e executada no cluster nesta fase.

import os
import sys
from datetime import datetime

import dotenv
from kubernetes import client, config, watch
from openai import OpenAI


# Le as variaveis do .env e valida se tudo obrigatorio esta preenchido.
# Se faltar algo, o script para imediatamente com mensagem de erro.
def load_env():
    dotenv.load_dotenv()
    required = ["AI_BASE_URL", "MODEL_NAME", "MONITOR_NAMESPACES", "OPERATION_MODE"]
    missing = [r for r in required if not os.getenv(r)]
    if missing:
        print(f"[VIGIA][ERRO] Variaveis ausentes no .env: {', '.join(missing)}")
        sys.exit(1)


# Conecta no cluster Kubernetes.
# Primeiro tenta usar o ~/.kube/config (minikube, kubectl).
# Se nao encontrar, tenta rodar de dentro de um Pod (in-cluster).
def get_k8s_client():
    try:
        config.load_kube_config()
    except Exception:
        config.load_incluster_config()
    return client.CoreV1Api()


# Fica escutando os eventos do cluster em tempo real.
# Filtra apenas os eventos de Pods que indicam problema real:
# Failed, BackOff, CrashLoopBackOff, ImagePullBackOff, OOMKilled, etc.
# Cada evento encontrado e devolvido para o loop principal processar.
def get_relevant_events(v1):
    w = watch.Watch()
    print("[VIGIA] Monitorando eventos do cluster...")
    print("[VIGIA] Aguardando incidentes... (Ctrl+C para sair)\n")
    for event in w.stream(v1.list_event_for_all_namespaces):
        obj = event["object"]
        if obj.involved_object.kind != "Pod":
            continue
        if obj.type == "Warning" and obj.reason in ("Failed", "BackOff", "FailedScheduling"):
            yield obj
        if obj.message and any(term in obj.message for term in ["CrashLoopBackOff", "ImagePullBackOff", "ErrImagePull", "OOMKilled"]):
            yield obj


# Busca os detalhes do Pod e pega os ultimos 50 linhas de log.
# Monta um texto com fase, restarts e estados dos containers.
# Esse texto vira a "evidencia" enviada para a IA diagnosticar.
def collect_evidence(v1, namespace, pod_name):
    try:
        pod = v1.read_namespaced_pod(name=pod_name, namespace=namespace)
        try:
            logs = v1.read_namespaced_pod_log(name=pod_name, namespace=namespace, tail_lines=50)
        except Exception as e:
            logs = f"Logs indisponiveis: {e}"

        restarts = sum(c.restart_count for c in (pod.status.container_statuses or []))
        container_states = [c.state.to_dict() for c in (pod.status.container_statuses or [])]

        evidence = f"""POD: {pod_name}
NAMESPACE: {namespace}
FASE: {pod.status.phase}
RESTARTS: {restarts}
ESTADOS DOS CONTAINERS: {container_states}
LOGS (ultimas 50 linhas):
{logs}
"""
        return evidence
    except Exception as e:
        return f"Erro ao coletar evidencias: {e}"


# Envia as evidencias para o modelo de IA (Ollama ou OpenAI).
# O prompt instrui a IA a responder no formato fixo: causa, severidade, acao, justificativa.
# Temperatura baixa (0.2) para respostas mais deterministicas e menos criativas.
def diagnose(client_ai, model, evidence):
    prompt = f"""Voce e um SRE senior especialista em Kubernetes.
Analise o incidente abaixo e responda EXATAMENTE nesse formato:

1. Causa raiz provavel:
2. Severidade: (BAIXA / MEDIA / ALTA / CRITICA)
3. Acao sugerida: (segura, reversivel e especifica)
4. Justificativa: (1 paragrafo curto)

Dados do incidente:
{evidence}
"""
    try:
        response = client_ai.chat.completions.create(
            model=model,
            messages=[{"role": "user", "content": prompt}],
            temperature=0.2,
        )
        return response.choices[0].message.content
    except Exception as e:
        return f"Falha ao consultar IA: {e}"


# Ponto de entrada do programa.
# Carrega configs, conecta no K8s e na IA, e entra no loop de monitoramento.
# Para cada incidente detectado: coleta evidencias, diagnostica e imprime o laudo.
# O modo de operacao (dry-run, approval, auto) so imprime o status; nenhuma acao e tomada ainda.
def main():
    load_env()
    v1 = get_k8s_client()

    ai_base = os.getenv("AI_BASE_URL")
    ai_key = os.getenv("AI_API_KEY") or "vigia"
    model = os.getenv("MODEL_NAME")
    mode = os.getenv("OPERATION_MODE", "dry-run")

    client_ai = OpenAI(base_url=ai_base, api_key=ai_key)

    print(f"[VIGIA] Modo: {mode.upper()}")
    print(f"[VIGIA] Modelo: {model}")

    try:
        for event in get_relevant_events(v1):
            now = datetime.now().isoformat()
            ns = event.metadata.namespace
            pod = event.involved_object.name

            print(f"\n{'='*60}")
            print(f"[ALERTA] {now} | {event.reason} | {ns}/{pod}")
            print(f"Mensagem: {event.message}")
            print(f"{'='*60}")

            evidence = collect_evidence(v1, ns, pod)
            print("[VIGIA] Coletando evidencias...")

            diagnosis = diagnose(client_ai, model, evidence)
            print(f"\n[DIAGNOSTICO]\n{diagnosis}\n")

            if mode == "dry-run":
                print("[MODO] dry-run: nenhuma acao executada no cluster.")
            elif mode == "approval":
                print("[MODO] approval: acao proposta, aguardando aprovacao humana...")
            elif mode == "auto":
                print("[MODO] auto: acao automatica desabilitada na Fase 1.")

            print("-" * 60)

    except KeyboardInterrupt:
        print("\n[VIGIA] Encerrando.")
        sys.exit(0)


if __name__ == "__main__":
    main()