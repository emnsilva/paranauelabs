#!/bin/bash
NOME_ARQUIVO="logs/Log$(date +%Y%m%d).log"
echo "⚡ Estressor - Arquivo: $NOME_ARQUIVO"
mkdir -p logs
echo "[$(date '+%H:%M:%S')] WARN: 🔥 Estressor iniciado" >> "$NOME_ARQUIVO"

inicio=$(date +%s)
while [ $(($(date +%s) - inicio)) -lt 180 ]; do
    case $((RANDOM % 4)) in
        0) stress-ng --cpu $((4 + RANDOM % 4)) --timeout 20s ;;
        1) stress-ng --vm 2 --vm-bytes $((800 + RANDOM % 1200))M --timeout 18s ;;
        2) stress-ng --io 2 --timeout 15s ;;
        3) stress-ng --cpu 3 --vm 1 --vm-bytes 700M --io 1 --timeout 22s ;;
    esac
    sleep $((3 + RANDOM % 4))
done

echo "[$(date '+%H:%M:%S')] ✅ Estressor concluido" >> "$NOME_ARQUIVO"
echo "✅ Concluido - Verifique $NOME_ARQUIVO"