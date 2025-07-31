package main

import (
	"fmt"
	"log"
	"os"
	"os/exec"
	"runtime"
	"strings"
)

func main() {
	if os.Geteuid() != 0 {
		exec.Command("sudo", append([]string{os.Args[0]}, os.Args[1:]...)...).Run()
		return
	}

	fmt.Println("[→] Instalando ferramentas...")
	pkgCmd := "apt install -y"
	if _, err := os.Stat("/etc/redhat-release"); err == nil {
		pkgCmd = "yum install -y"
	}
	execCommand(strings.Fields(pkgCmd + " curl docker.io")...)

	fmt.Println("[→] Configurando orquestração...")
	dcVersion := "v2.27.0"
	execCommand("curl", "-SL", fmt.Sprintf(
		"https://github.com/docker/compose/releases/download/%s/docker-compose-linux-%s",
		dcVersion, runtime.GOARCH), "-o", "/usr/local/bin/docker-compose")
	execCommand("chmod", "+x", "/usr/local/bin/docker-compose")
	execCommand("ln", "-sf", "/usr/local/bin/docker-compose", "/usr/bin/docker-compose")

	fmt.Println("[→] Baixando imagens oficiais...")
	for _, img := range []string{
		"nginx:latest", "postgres:15", 
		"alexeiled/stress-ng:latest", "prom/node-exporter",
	} {
		execCommand("docker", "pull", img)
	}

	fmt.Println("[→] Ativando serviços...")
	execCommand("systemctl", "enable", "--now", "docker")
	if user := os.Getenv("SUDO_USER"); user != "" {
		execCommand("usermod", "-aG", "docker", user)
	}

	fmt.Println("\n[✔] Infraestrutura operacional:")
	for _, t := range []struct{ name, cmd string }{
		{"Go", "go version"}, {"Docker", "docker --version"}, 
		{"Docker Compose", "docker-compose --version"},
	} {
		if out, err := exec.Command("sh", "-c", t.cmd).Output(); err == nil {
			fmt.Printf("    %s: %s", t.name, strings.TrimSpace(string(out)))
		}
	}
}

func execCommand(args ...string) {
	fmt.Printf("[+] Executando: %s\n", strings.Join(args, " "))
	cmd := exec.Command(args[0], args[1:]...)
	cmd.Stdout, cmd.Stderr = os.Stdout, os.Stderr
	if err := cmd.Run(); err != nil {
		log.Fatalf("[✗] Falha: %v\n", err)
	}
}