#!/bin/bash
echo "🏥 ESTRESSADOR DE PICO - 3 MINUTOS"
INICIO=$(date +%s)
FIM=$((INICIO + 180))

log() {
    echo "[$(date '+%H:%M:%S')] $1: $2"
}

log "INFO" "Iniciando estressador com variação radical"

while [ $(date +%s) -lt $FIM ]; do
    SEGUNDO=$((($(date +%s) - INICIO)))
    
    if [ $SEGUNDO -lt 45 ]; then
        log "INFO" "FASE 1: Estresse Leve" && stress-ng --cpu 1 --timeout 15s
        
    elif [ $SEGUNDO -lt 90 ]; then
        log "WARN" "FASE 2: Estresse Moderado" && stress-ng --cpu 2 --vm 1 --vm-bytes 500M --timeout 20s
        
    elif [ $SEGUNDO -lt 135 ]; then
        log "ERROR" "FASE 3: Estresse Radical" && stress-ng --cpu 4 --vm 2 --vm-bytes 1G --timeout 25s
        
    else
        log "ERROR" "FASE 4: EMERGÊNCIA MÁXIMA" && stress-ng --cpu 8 --vm 4 --vm-bytes 2G --timeout 30s
    fi
    
    sleep 5
done

log "INFO" "✅ ESTRESSADOR CONCLUÍDO"