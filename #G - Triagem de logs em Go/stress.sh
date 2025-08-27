#!/bin/bash
# === ESTRESSADOR SUPER INTENSO ===

echo "⚡ ESTRESSADOR SUPER INTENSO - 3min"
echo "📁 Logs em: logs/prontuario.log"
echo "🔥 Gerando apenas WARN e ERROR!"
INICIO=$(date +%s)
FIM=$((INICIO + 180))

escrever_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1: $2" >> logs/prontuario.log
}

mkdir -p logs
escrever_log "WARN" "🚨 ESTRESSADOR SUPER INTENSO INICIADO - PREPARAR PARA CAOS"

while [ $(date +%s) -lt $FIM ]; do
    SEGUNDO=$((($(date +%s) - INICIO)))
    
    # ⭐⭐ ESTRESSE MÁXIMO: Sempre operações intensas ⭐⭐
    case $((RANDOM % 4)) in
        0)
            escrever_log "ERROR" "💥 SURTO: CPU EXTREMO" 
            stress-ng --cpu $((4 + RANDOM % 4)) --timeout $((20 + RANDOM % 10))s
            ;;
        1)
            escrever_log "ERROR" "💥 SURTO: MEMÓRIA MASSIVA"
            stress-ng --vm $((2 + RANDOM % 3)) --vm-bytes $((800 + RANDOM % 1200))M --timeout $((18 + RANDOM % 12))s
            ;;
        2)
            escrever_log "WARN" "⚠️ SURTO: DISCO RADICAL"
            stress-ng --io $((2 + RANDOM % 3)) --timeout $((15 + RANDOM % 15))s
            dd if=/dev/zero of=/tmp/caos_$RANDOM.bin bs=1M count=$((50 + RANDOM % 100)) status=none &
            ;;
        3)
            escrever_log "ERROR" "💥 SURTO: CPU+MEM+IO COMBINADO"
            stress-ng --cpu $((3 + RANDOM % 5)) --vm $((1 + RANDOM % 2)) --vm-bytes $((600 + RANDOM % 800))M --io $((1 + RANDOM % 2)) --timeout $((25 + RANDOM % 5))s
            ;;
    esac
    
    # ⭐⭐ INTERVALO CURTO: Mais estresse, menos descanso ⭐⭐
    sleep $((2 + RANDOM % 5))
done

escrever_log "WARN" "✅ ESTRESSADOR SUPER INTENSO CONCLUÍDO"
echo "✅ Estresse máximo aplicado - Verifique logs WARN/ERROR!"