#!/bin/bash
echo "⚡ Estressador - 3min"
echo "📁 Logs em: logs/prontuario.log"
INICIO=$(date +%s)
FIM=$((INICIO + 180))

escrever_log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1: $2" >> logs/prontuario.log
}

mkdir -p logs
escrever_log "INFO" "Estressador iniciado - Padrões imprevisíveis"

while [ $(date +%s) -lt $FIM ]; do
    SEGUNDO=$((($(date +%s) - INICIO)))
    
    # ⭐⭐ COMPORTAMENTO ALEATÓRIO ⭐⭐
    case $((RANDOM % 6)) in
        0)
            escrever_log "INFO" "SURTO: Estresse leve aleatório" 
            stress-ng --cpu $((1 + RANDOM % 4)) --timeout $((10 + RANDOM % 15))s
            ;;
        1)
            escrever_log "WARN" "SURTO: Estresse moderado aleatório"
            stress-ng --cpu $((2 + RANDOM % 4)) --vm 1 --vm-bytes $((100 + RANDOM % 400))M --timeout $((15 + RANDOM % 10))s
            ;;
        2)
            escrever_log "ERROR" "SURTO: Estresse radical aleatório"
            stress-ng --cpu $((4 + RANDOM % 4)) --vm 2 --vm-bytes $((500 + RANDOM % 500))M --io 1 --timeout $((20 + RANDOM % 10))s
            ;;
        3)
            escrever_log "INFO" "SURTO: IO aleatório"
            stress-ng --io $((1 + RANDOM % 3)) --timeout $((12 + RANDOM % 13))s
            ;;
        4)
            escrever_log "WARN" "SURTO: Memória aleatória" 
            stress-ng --vm $((1 + RANDOM % 3)) --vm-bytes $((200 + RANDOM % 800))M --timeout $((18 + RANDOM % 7))s
            ;;
        5)
            escrever_log "ERROR" "SURTO: CPU+Memória aleatório"
            stress-ng --cpu $((3 + RANDOM % 5)) --vm $((1 + RANDOM % 2)) --vm-bytes $((300 + RANDOM % 700))M --timeout $((16 + RANDOM % 9))s
            ;;
    esac
    
    # ⭐⭐ INTERVALO ALEATÓRIO ENTLE SURTOS ⭐⭐
    sleep $((3 + RANDOM % 12))
done

escrever_log "INFO" "✅ Estressador concluído"
echo "✅ Caos concluído!"