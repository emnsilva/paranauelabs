#!/bin/bash
echo "⚡ Estressador Iniciado (3min)"
INICIO=$(date +%s)  # Marca o tempo de início
FIM=$((INICIO + 180))  # Calcula tempo final (3 minutos)

# Função auxiliar para log com timestamp
log() { echo "[$(date '+%H:%M:%S')] $1: $2"; }

# === LOOP PRINCIPAL ===
# Calcula segundos decorridos desde o início
while [ $(date +%s) -lt $FIM ]; do
    SEG=$((($(date +%s) - INICIO)))
    
    # === FASE 1: 0-45s - ESTRESSE LEVE ===
    if [ $SEG -lt 45 ]; then
        log "INFO" "Fase Leve" 
        stress-ng --cpu 1 --timeout 15s  # 1 core por 15s
    
    # === FASE 2: 45-90s - ESTRESSE MODERADO ===  
    elif [ $SEG -lt 90 ]; then
        log "WARN" "Fase Moderada" 
        stress-ng --cpu 2 --timeout 20s  # 2 cores por 20s
    
    # === FASE 3: 90-135s - ESTRESSE RADICAL ===
    elif [ $SEG -lt 135 ]; then
        log "ERROR" "Fase Radical" 
        stress-ng --cpu 4 --timeout 25s  # 4 cores por 25s
    
    # === FASE 4: 135-180s - EMERGÊNCIA ===
    else
        log "ERROR" "EMERGÊNCIA" 
        stress-ng --cpu 8 --timeout 30s  # 8 cores por 30s
    fi
    
    sleep 5  # Intervalo entre ciclos
done

log "INFO" "✅ Concluído"