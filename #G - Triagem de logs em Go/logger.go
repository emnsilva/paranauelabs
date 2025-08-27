package main
import ("fmt";"math/rand";"os";"time")

type Nivel string
const ( INFO Nivel = "INFO"; WARN Nivel = "WARN"; ERROR Nivel = "ERROR" )

type Logger struct { arquivo *os.File }

func NovoLogger() (*Logger, error) {
	os.MkdirAll("logs", 0755)
	nomeArquivo := fmt.Sprintf("logs/Log%s.log", time.Now().Format("20060102"))
	f, err := os.OpenFile(nomeArquivo, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil { return nil, err }
	return &Logger{arquivo: f}, nil
}

func (l *Logger) Registrar(nivel Nivel, msg string) {
	log := fmt.Sprintf("[%s] %s: %s\n", time.Now().Format("15:04:05"), nivel, msg)
	l.arquivo.WriteString(log)
}

func (l *Logger) Fechar() { l.arquivo.Close() }

func main() {
	logger, _ := NovoLogger()
	defer logger.Fechar()
	
	fmt.Printf("🏥 Logger - Arquivo: Log%s.log\n", time.Now().Format("20060102"))
	inicio := time.Now()
	for ciclo := 1; time.Since(inicio) < 3*time.Minute; ciclo++ {
		if rand.Intn(100) < 80 {
			valor := 80 + rand.Intn(20)
			tipos := []string{"CPU", "Memória", "Disco", "Rede"}
			sintomas := []string{"Febre Alta", "Hemorragia", "Infarto", "Congestionamento"}
			nivel := ERROR; if valor < 90 { nivel = WARN }
			logger.Registrar(nivel, fmt.Sprintf("%s - %s: %d%%", tipos[rand.Intn(4)], sintomas[rand.Intn(4)], valor))
		}
		time.Sleep(8 * time.Second)
	}
	logger.Registrar(WARN, "✅ Plantão concluído")
	fmt.Println("✅ Logger concluído")
}