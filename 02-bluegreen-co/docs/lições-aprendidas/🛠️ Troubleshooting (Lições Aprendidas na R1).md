Durante a execução, encontrei os seguintes desafios que estão documentados para referência futura:

1- **sh: curl: not found (Alpine):**
O Alpine não vem com curl ou iptables. O script installparanaue.sh precisa instalá-los via apk add iptables curl antes de rodar o instalador do k3s.
2- **k3s-agent em loop (exit code 1):**
Ocorre se uma instalação anterior do k3s for interrompida. É preciso rodar o uninstallparanaue.sh (que faz uma limpeza profunda dos mounts e interfaces de rede) e reiniciar a VM antes de tentar novamente.
3- **Erro no sysctl --system:**
O BusyBox do Alpine não aceita a flag --system. A solução é usar sysctl -p /etc/sysctl.d/90-k3s.conf.
4- **kubectl não encontrado no host:**
Como não instalamos o kubectl no host físico, os comandos de status no Makefile foram ajustados para rodar via SSH dentro do control plane (ssh alpine@IP "sudo k3s kubectl get nodes").

## 🎁 Bônus:

Resolvendo o problema da senha de vez. Se você quiser automatizar isso no próprio `Makefile`, basta adicionar esta regra:

```
makefile

setup-ssh:

	@echo "🔑 Configurando SSH e Sudo sem senha..."
	@for ip in $(IP_CP) $(IP_W1) $(IP_W2); do \
		ssh-copy-id alpine@$$ip; \
		ssh alpine@$$ip "echo 'alpine ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/alpine > /dev/null && sudo chmod 0440 /etc/sudoers.d/alpine"; \
	done
	@echo "✅ Pronto! O 'make lab-up' agora rodará sem senhas."
```

Aí, sempre que criar o lab do zero, você roda make setup-ssh uma vez, e depois make lab-up flui sem interrupções!