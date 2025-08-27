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

// ⭐⭐ MONITORAMENTO COM MUITO MAIS ESTRESSE ⭐⭐
func (l *Logger) monitorarSintomasIntensos(ciclo int) {
    rand.Seed(time.Now().UnixNano() + int64(ciclo))
    
    sintomasCPU := []string{
        "FEBRE ALTA DE CPU", "OVERCLOCK PERIGOSO", "NÚCLEOS EM COLAPSO", 
        "TEMPERATURA CRÍTICA", "THROTTLING ATIVADO", "PROCESSADOR SUPRA-AQUECIDO",
    }
    
    sintomasMemoria := []string{
        "HEMORRAGIA DE RAM", "VAZAMENTO MASSIVO", "SWAP CONGESTIONADO",
        "OUT OF MEMORY IMINENTE", "ALOCAÇÃO DESCONTROLADA", "HEAP EM CRISE",
    }
    
    sintomasDisco := []string{
        "INFARTO DE DISCO", "TAQUICARDIA DE IO", "SETORES CORRUPTOS",
        "LATÊNCIA CRÍTICA", "THROUGHPUT COLAPSADO", "FILESYSTEM EM PANE",
    }
    
    sintomasRede := []string{
        "PACKET LOSS CRÍTICO", "LATÊNCIA EXTREMA", "DNS INTOXICADO",
        "CONEXÃO INTERMITENTE", "BANDWIDTH CONGESTIONADO", "TIMEOUT GENERALIZADO",
    }
    
    // ⭐⭐ MAIS ESTRESSE: 70% de chance de gerar sintomas graves ⭐⭐
    if rand.Intn(100) < 70 {
        tipos := []struct{
            nome    string
            sintomas []string
            peso    int
        }{
            {"CPU", sintomasCPU, 35},
            {"Memória", sintomasMemoria, 30},
            {"Disco", sintomasDisco, 25},
            {"Rede", sintomasRede, 10},
        }
        
        tipoEscolhido := tipos[rand.Intn(len(tipos))]
        sintoma := tipoEscolhido.sintomas[rand.Intn(len(tipoEscolhido.sintomas))]
        
        // ⭐⭐ VALORES MAIS ALTOS: 80-100% para mais ERROS ⭐⭐
        valor := 80 + rand.Intn(20) // 80-100%
        
        // ⭐⭐ DISTRIBUIÇÃO MAIS AGRESSIVA: Menos INFO, mais WARN/ERROR ⭐⭐
        var nivel Nivel
        switch {
        case valor > 95:
            nivel = ERROR // 25% de chance
        case valor > 85:
            nivel = WARN  // 50% de chance  
        default:
            nivel = INFO  // 25% de chance
        }
        
        l.Registrar(nivel, fmt.Sprintf("%s - %s: %d%%", tipoEscolhido.nome, sintoma, valor))
    }
    
    // ⭐⭐ EVENTOS CATASTRÓFICOS ALEATÓRIOS ⭐⭐
    if rand.Intn(100) > 80 { // 20% de chance de evento catastrófico
        catastrofes := []string{
            "🚨 COLAPSO SISTÊMICO IMINENTE - INTERVENÇÃO IMEDIATA",
            "💥 FALHA EM CASCATA DETECTADA - TODOS OS SISTEMAS AFETADOS",
            "🔥 SUPERAQUECIMENTO CRÍTICO - DESLIGAMENTO DE EMERGÊNCIA",
            "⚡ CURTO-CIRCUITO VIRTUAL - DANOS IRREVERSÍVEIS",
            "🌪️ TORNADO DE BUGS - CONTAMINAÇÃO GENERALIZADA",
        }
        l.Registrar(ERROR, catastrofes[rand.Intn(len(catastrofes))])
    }
}

func main() {
    // ⭐⭐ MUDA PARA WARN: Só registra WARN e ERROR ⭐⭐
    logger, err := NovoLogger(WARN)
    if err != nil { panic("Erro: " + err.Error()) }
    defer logger.Fechar()

    fmt.Println("🏥 HOSPITAL DE LOGS - PLANTÃO DE ESTRESSE MÁXIMO")
    fmt.Println("📍 Prontuário: logs/prontuario.log")
    fmt.Println("⚡ FILTRO: Apenas WARN e ERROR serão registrados!")
    fmt.Println("🔥 Preparando para estresse intenso...")
    fmt.Println("==========================================")

    inicio := time.Now()
    fim := inicio.Add(3 * time.Minute)
    ciclo := 1

    logger.Registrar(WARN, "🚨 PLANTÃO DE ESTRESSE MÁXIMO INICIADO - PREPARAR PARA EMERGÊNCIAS")

    for time.Now().Before(fim) {
        tempoRestante := time.Until(fim).Round(time.Second)
        
        if ciclo%3 == 0 { // A cada 3 ciclos
            logger.Registrar(WARN, fmt.Sprintf("⏰ Ciclo %d - %s restantes", ciclo, tempoRestante))
        }
        
        // ⭐⭐ MONITORAMENTO COM ESTRESSE INTENSO ⭐⭐
        logger.monitorarSintomasIntensos(ciclo)
        
        time.Sleep(8 * time.Second)
        ciclo++
    }

    logger.Registrar(WARN, fmt.Sprintf("✅ PLANTÃO CONCLUÍDO - %d ciclos de estresse intenso", ciclo-1))
    fmt.Println("✅ Plantão de estresse máximo concluído!")
    fmt.Println("📋 Prontuário com mostly WARN/ERROR salvo!")
}