package main

import (
	"fmt"
	"os"
	"time"
)

type Nivel string

const (
	INFO  Nivel = "INFO"
	WARN  Nivel = "WARN"
	ERROR Nivel = "ERROR"
)

type Logger struct {
	prontuario       *os.File
	protocoloTriagem Nivel
}

func NovoHospital(nomeProntuario string, triagem Nivel) (*Logger, error) {
	prontuario, err := os.OpenFile(nomeProntuario, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
	if err != nil {
		return nil, fmt.Errorf("não foi possível abrir o prontuário: %v", err)
	}
	return &Logger{prontuario: prontuario, protocoloTriagem: triagem}, nil
}

func (l *Logger) deveAtender(gravidade Nivel) bool {
	prioridades := map[Nivel]int{INFO: 1, WARN: 2, ERROR: 3}
	return prioridades[gravidade] >= prioridades[l.protocoloTriagem]
}

func (l *Logger) AtenderPaciente(gravidade Nivel, sintomas string) error {
	if !l.deveAtender(gravidade) {
		return nil
	}

	ficha := fmt.Sprintf("[%s] %s: %s\n",
		time.Now().Format("2006-01-02 15:04:05"),
		gravidade,
		sintomas)

	_, err := l.prontuario.WriteString(ficha)
	return err
}

func (l *Logger) FecharHospital() error {
	return l.prontuario.Close()
}

func (l *Logger) monitorarSinaisReais() {
	now := time.Now()
	segundo := now.Second()
	
	usoCPU := 70 + (segundo % 30)
	usoMemoria := 60 + (segundo % 40)
	usoDisco := 50 + (segundo % 50)
	
	if usoCPU > 85 {
		l.AtenderPaciente(WARN, fmt.Sprintf("Febre de CPU crítica: %d%% - Resfriamento necessário", usoCPU))
	} else if usoCPU > 75 {
		l.AtenderPaciente(INFO, fmt.Sprintf("CPU elevada: %d%% - Monitorar", usoCPU))
	}
	
	if usoMemoria > 90 {
		l.AtenderPaciente(ERROR, fmt.Sprintf("Hemorragia de memória: %d%% - Transfusão necessária", usoMemoria))
	} else if usoMemoria > 80 {
		l.AtenderPaciente(WARN, fmt.Sprintf("Pressão memória alta: %d%% - Risco", usoMemoria))
	}
	
	if usoDisco > 95 {
		l.AtenderPaciente(ERROR, fmt.Sprintf("INFARTO DE DISCO: %d%% - PARADA CARDÍACA IMINENTE", usoDisco))
	} else if usoDisco > 85 {
		l.AtenderPaciente(WARN, fmt.Sprintf("Arritmia de disco: %d%% - Taquicardia", usoDisco))
	}
}

func main() {
	hospital, err := NovoHospital("prontuario_medico.log", INFO)
	if err != nil {
		panic("🚨 HOSPITAL INDISPONÍVEL: " + err.Error())
	}
	defer hospital.FecharHospital()

	fmt.Println("🏥 HOSPITAL DE LOGS - PLANTÃO DE 3 MINUTOS")
	fmt.Println("📍 Prontuário: prontuario_medico.log")
	fmt.Println("⏰ Duração: 3 minutos com variação radical")
	fmt.Println("==========================================")

	inicio := time.Now()
	fim := inicio.Add(3 * time.Minute)
	ciclo := 1

	hospital.AtenderPaciente(INFO, "Plantão de 3 minutos iniciado - Variação radical de estresse")

	for time.Now().Before(fim) {
		tempoRestante := time.Until(fim).Round(time.Second)
		hospital.AtenderPaciente(INFO, fmt.Sprintf("Ciclo %d - %s restantes", ciclo, tempoRestante))
		hospital.monitorarSinaisReais()
		time.Sleep(10 * time.Second)
		ciclo++
	}

	hospital.AtenderPaciente(INFO, fmt.Sprintf("✅ PLANTÃO CONCLUÍDO - %d ciclos completados", ciclo-1))
	fmt.Println("✅ Plantão de 3 minutos concluído!")
}