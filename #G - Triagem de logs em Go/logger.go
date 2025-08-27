package main

import (
	"fmt"
	"math/rand"
	"os"
	"path/filepath"
	"time"
)

type Nivel string
const ( INFO Nivel = "INFO"; WARN Nivel = "WARN"; ERROR Nivel = "ERROR" )

type Logger struct {
    arquivo *os.File
    nivelMinimo Nivel
}

func NovoLogger(nivel Nivel) (*Logger, error) {
    if err := os.MkdirAll("logs", 0755); err != nil {
        return nil, fmt.Errorf("erro ao criar pasta logs: %v", err)
    }
    
    caminhoCompleto := filepath.Join("logs", "prontuario.log")
    f, err := os.OpenFile(caminhoCompleto, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
    if err != nil { return nil, err }
    
    return &Logger{arquivo: f, nivelMinimo: nivel}, nil
}

func (l *Logger) deveRegistrar(nivel Nivel) bool {
    p := map[Nivel]int{INFO: 1, WARN: 2, ERROR: 3}
    return p[nivel] >= p[l.nivelMinimo]
}

func (l *Logger) Registrar(nivel Nivel, msg string) error {
    if !l.deveRegistrar(nivel) { return nil }
    
    log := fmt.Sprintf("[%s] %s: %s\n", 
        time.Now().Format("2006-01-02 15:04:05"),
        nivel, msg)
        
    _, err := l.arquivo.WriteString(log)
    return err
}

func (l *Logger) Fechar() error { return l.arquivo.Close() }

// ⭐⭐ SINTOMAS EMBARALHADOS E IMPREVISÍVEIS ⭐⭐
func (l *Logger) monitorarSintomasAleatorios(ciclo int) {
    rand.Seed(time.Now().UnixNano() + int64(ciclo))
    
    // Gera sintomas aleatórios com padrões imprevisíveis
    sintomasCPU := []string{
        "Febre de CPU", "Overclock espontâneo", "Processador hiperativo", 
        "Cache congestionado", "Núcleos em colapso", "Temperatura crítica",
    }
    
    sintomasMemoria := []string{
        "Hemorragia de RAM", "Vazamento de memória", "Swap congestionado",
        "Buffer overload", "Alocação descontrolada", "Heap em crise",
    }
    
    sintomasDisco := []string{
        "Infarto de disco", "Taquicardia de IO", "Setores corruptos",
        "Latência crítica", "Throughput colapsado", "FileSystem em pane",
    }
    
    // ⭐⭐ EMBARALHA A ORDEM DOS SINTOMAS ⭐⭐
    sintomaCPU := sintomasCPU[rand.Intn(len(sintomasCPU))]
    sintomaMemoria := sintomasMemoria[rand.Intn(len(sintomasMemoria))]
    sintomaDisco := sintomasDisco[rand.Intn(len(sintomasDisco))]
    
    // ⭐⭐ VALORES ALEATÓRIOS NÃO LINEARES ⭐⭐
    usoCPU := 30 + rand.Intn(70)           // 30-100% (aleatório)
    usoMemoria := 40 + rand.Intn(60)       // 40-100% (aleatório)  
    usoDisco := 20 + rand.Intn(80)         // 20-100% (aleatório)
    
    // ⭐⭐ NIVEL ALEATÓRIO PARA CADA SINTOMA ⭐⭐
    niveis := []Nivel{INFO, WARN, ERROR}
    nivelCPU := niveis[rand.Intn(len(niveis))]
    nivelMemoria := niveis[rand.Intn(len(niveis))]
    nivelDisco := niveis[rand.Intn(len(niveis))]
    
    // Registra sintomas embaralhados
    if rand.Intn(100) > 30 { // 70% de chance de registrar CPU
        l.Registrar(nivelCPU, fmt.Sprintf("%s: %d%%", sintomaCPU, usoCPU))
    }
    
    if rand.Intn(100) > 40 { // 60% de chance de registrar Memória
        l.Registrar(nivelMemoria, fmt.Sprintf("%s: %d%%", sintomaMemoria, usoMemoria))
    }
    
    if rand.Intn(100) > 50 { // 50% de chance de registrar Disco
        l.Registrar(nivelDisco, fmt.Sprintf("%s: %d%%", sintomaDisco, usoDisco))
    }
    
    // ⭐⭐ EVENTOS ESPECIAIS ALEATÓRIOS ⭐⭐
    if rand.Intn(100) > 90 { // 10% de chance de evento especial
        eventosEspeciais := []string{
            "Paciente em recuperação espontânea",
            "Sistema estabilizado misteriosamente", 
            "Crise resolvida sem intervenção",
            "Diagnóstico inconclusivo - sintomas sumiram",
            "Remissão completa dos sintomas",
        }
        l.Registrar(INFO, eventosEspeciais[rand.Intn(len(eventosEspeciais))])
    }
}

func main() {
    logger, err := NovoLogger(INFO)
    if err != nil { panic("Erro: " + err.Error()) }
    defer logger.Fechar()

    fmt.Println("🏥 HOSPITAL DE LOGS - PLANTÃO")
    fmt.Println("📍 Prontuário: logs/prontuario.log")
    fmt.Println("==========================================")

    inicio := time.Now()
    fim := inicio.Add(3 * time.Minute)
    ciclo := 1

    logger.Registrar(INFO, "Plantão iniciado")

    for time.Now().Before(fim) {
        tempoRestante := time.Until(fim).Round(time.Second)
        
        logger.Registrar(INFO, fmt.Sprintf("Ciclo %d - %s restantes", ciclo, tempoRestante))
        
        // ⭐⭐ MONITORAMENTO COM SINTOMAS EMBARALHADOS ⭐⭐
        logger.monitorarSintomasAleatorios(ciclo)
        
        time.Sleep(8 * time.Second) // Intervalo variado
        ciclo++
    }

    logger.Registrar(INFO, fmt.Sprintf("✅ PLANTÃO CONCLUÍDO - %d ciclos", ciclo-1))
    fmt.Println("✅ Plantão concluído!")
}