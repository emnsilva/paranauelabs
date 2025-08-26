package main

import (
	"fmt"
	"os"
	"time"
)

// === BLOCO 1: DEFINIÇÕES BÁSICAS ===
// Define os tipos de níveis de log (como constantes tipadas)
type Nivel string
const ( 
    INFO  Nivel = "INFO"   // Eventos normais do sistema
    WARN  Nivel = "WARN"   // Situações que exigem atenção  
    ERROR Nivel = "ERROR"  // Falhas críticas que precisam de ação
)

// === BLOCO 2: ESTRUTURA PRINCIPAL ===  
// Logger é o coração do sistema - armazena configuração e estado
type Logger struct {
    arquivo *os.File     // Arquivo onde os logs serão escritos
    nivelMinimo Nivel    // Filtro: nível mínimo para registrar
}

// === BLOCO 3: INICIALIZAÇÃO ===
// Cria e configura uma nova instância do Logger
func NovoLogger(arquivo string, nivel Nivel) (*Logger, error) {
    // Abre o arquivo em modo append (adiciona ao final), cria se não existir
    f, err := os.OpenFile(arquivo, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
    if err != nil { return nil, err } // Se der erro, retorna logo
    
    return &Logger{arquivo: f, nivelMinimo: nivel}, nil // Retorna logger configurado
}

// === BLOCO 4: FILTRO DE TRIAGEM ===
// Decide se uma mensagem deve ser registrada baseado na prioridade
func (l *Logger) deveRegistrar(nivel Nivel) bool {
    // Mapa de prioridades: quanto maior o número, mais urgente
    p := map[Nivel]int{INFO: 1, WARN: 2, ERROR: 3}
    return p[nivel] >= p[l.nivelMinimo] // Só registra se prioridade >= mínima
}

// === BLOCO 5: REGISTRO PRINCIPAL ===  
// Método público para registrar mensagens (o coração do logger)
func (l *Logger) Registrar(nivel Nivel, msg string) error {
    if !l.deveRegistrar(nivel) { return nil } // Pula se não atender ao filtro
    
    // Formata a mensagem com timestamp e nível
    log := fmt.Sprintf("[%s] %s: %s\n", 
        time.Now().Format("2006-01-02 15:04:05"), // Timestamp formatado
        nivel,    // Nível de gravidade
        msg)      // Mensagem descritiva
        
    // Escreve no arquivo e retorna qualquer erro
    _, err := l.arquivo.WriteString(log)
    return err
}

// === BLOCO 6: LIMPEZA ===
// Fecha o arquivo adequadamente - IMPORTANTE para evitar corrupção
func (l *Logger) Fechar() error { return l.arquivo.Close() }

// === BLOCO 7: EXEMPLO DE USO ===
func main() {
    // Cria logger que registra a partir de INFO
    logger, err := NovoLogger("logs.log", INFO)
    if err != nil { panic("Erro: " + err.Error()) }
    defer logger.Fechar() // Garante fechamento mesmo com erro

    // Registra exemplos de diferentes níveis
    logger.Registrar(INFO, "Sistema iniciado")       // ✅ Será registrado
    logger.Registrar(WARN, "CPU acima de 80%")       // ✅ Será registrado  
    logger.Registrar(ERROR, "Disco cheio")           // ✅ Será registrado
    
    fmt.Println("Logs registrados em logs.log")
}