package main

import (
    "fmt"
    "os"
    "time"
)

// Definindo os tipos de gravidade dos casos

type Nivel string

const (
    INFO  Nivel = "INFO"   // Caso rotineiro (check-up)
    WARN  Nivel = "WARN"   // Caso urgente (observação)
    ERROR Nivel = "ERROR"  // Caso emergencial (UTI)
)

// Estrutura principal que controla todo o sistema

type Logger struct {
    prontuario  *os.File  // Arquivo de registros (prontuário)
    triagemMinima Nivel   // Protocolo de atendimento
}

// Registro individual de cada atendimento

type MensagemLog struct {
    horario    time.Time // Horário de chegada
    gravidade  Nivel     // Tipo de caso
    sintomas   string    // Descrição do ocorrido
}

// Função que abre e prepara o hospital para funcionar

func NovoHospital(nomeProntuario string, protocoloTriagem Nivel) (*Logger, error) {
    // Abre o prontuário médico (arquivo de logs)
    prontuario, err := os.OpenFile(nomeProntuario, os.O_APPEND|os.O_CREATE|os.O_WRONLY, 0644)
    if err != nil {
        return nil, fmt.Errorf("não foi possível abrir o prontuário: %v", err)
    }

    // Retorna o hospital pronto para funcionar
    return &Logger{
        prontuario:    prontuario,
        triagemMinima: protocoloTriagem,
    }, nil
}

// Método que decide se o caso será atendido

func (l *Logger) deveAtender(gravidade Nivel) bool {
    // Mapa de prioridades (quanto maior o número, mais grave)
    prioridades := map[Nivel]int{
        INFO:  1,  // Prioridade baixa
        WARN:  2,  // Prioridade média
        ERROR: 3,  // Prioridade alta
    }
    return prioridades[gravidade] >= prioridades[l.triagemMinima]
}

// Método principal que registra o atendimento

func (l *Logger) AtenderPaciente(gravidade Nivel, sintomas string) error {
    // Verifica se o caso atende ao protocolo de triagem
    if !l.deveAtender(gravidade) {
        return nil // Caso liberado (não grave o suficiente)
    }

    // Preenche a ficha do paciente
    paciente := MensagemLog{
        horario:   time.Now(),
        gravidade: gravidade,
        sintomas:  sintomas,
    }

    // Formata o registro do atendimento
    registro := fmt.Sprintf("[%s] %s: %s\n",
        paciente.horario.Format("2006-01-02 15:04:05"),
        paciente.gravidade,
        paciente.sintomas)

    // Registra no prontuário médico
    _, err := l.prontuario.WriteString(registro)
    if err != nil {
        return fmt.Errorf("erro ao registrar no prontuário: %v", err)
    }

    return nil
}

// Método para fechar o prontuário adequadamente

func (l *Logger) FecharHospital() error {
    return l.prontuario.Close()
}

// Programa principal - onde o hospital funciona

func main() {
    // Inaugura o hospital com protocolo de triagem
    hospital, err := NovoHospital("prontuario.log", WARN)
    if err != nil {
        panic("Falha na inauguração do hospital: " + err.Error())
    }
    defer hospital.FecharHospital() // Garante fechamento adequado

    // Pacientes chegando para atendimento
    hospital.AtenderPaciente(INFO, "Sistema iniciado - check-up rotineiro")
    hospital.AtenderPaciente(WARN, "CPU acima de 80% - febre alta")
    hospital.AtenderPaciente(ERROR, "Disco cheio - parada cardíaca!")
    hospital.AtenderPaciente(INFO, "Backup concluído - exames de rotina")

    fmt.Println("Plantão concluído! Verifique o prontuário em 'prontuario.log'")
}