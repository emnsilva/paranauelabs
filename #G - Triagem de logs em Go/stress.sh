#!/bin/bash
# PLANTÃO MÉDICO EXTENDIDO - 3 MINUTOS DE SIMULAÇÃO

echo "🏥 INICIANDO PLANTÃO MÉDICO DE 3 MINUTOS..."
echo "⏰ Duração: 180 segundos de monitoramento intensivo"
echo "=================================================="

# Timestamp de início
INICIO=$(date +%s)
FIM=$((INICIO + 180))

# Função para log com timestamp médico
log_mensagem() {
    echo "[$(date '+%H:%M:%S')] $1: $2"
}

# Contador de ciclos
CICLO=1

log_mensagem "INFO" "Plantão de 3 minutos iniciado - Monitoramento contínuo"

while [ $(date +%s) -lt $FIM ]; do
    echo ""
    log_mensagem "INFO" "=== CICLO $CICLO ==="
    
    # 1. 📈 Febre de CPU Intermitente (30s)
    log_mensagem "WARN" "Sintoma 1: Febre de CPU (30s)"
    stress-ng --cpu 2 --timeout 30s
    log_mensagem "WARN" "Febre controlada - CPU em repouso"
    
    # 2. 💾 Amnésia de Memória (20s)  
    log_mensagem "WARN" "Sintoma 2: Amnésia de Memória (20s)"
    stress-ng --vm 1 --vm-bytes 800M --timeout 20s
    log_mensagem "WARN" "Memória estabilizada"
    
    # 3. 🚨 Taquicardia de IO (15s)
    log_mensagem "ERROR" "Sintoma 3: Taquicardia de IO (15s)"
    stress-ng --io 2 --timeout 15s
    log_mensagem "ERROR" "Ritmo de IO normalizado"
    
    # 4. 📊 Checagem de Sinais Vitais (5s)
    log_mensagem "INFO" "Checagem de sinais vitais..."
    df -h . | tail -1 | awk '{print "💾 Disco: " $5}'
    free -m | awk 'NR==2{print "🧠 Memória: " $3/$2*100 "%"}'
    top -bn1 | grep "Cpu(s)" | awk '{print "🔥 CPU: " $2 "%"}'
    
    # 5. 🕐 Intervalo de repouso (10s)
    log_mensagem "INFO" "Intervalo de repouso (10s)"
    sleep 10
    
    ((CICLO++))
done

echo ""
echo "=================================================="
log_mensagem "INFO" "✅ PLANTÃO CONCLUÍDO - 3 minutos de simulação"
log_mensagem "INFO" "📊 Total de ciclos completados: $((CICLO-1))"
echo "📋 Verifique o prontuário completo em 'prontuario_medico.log'"