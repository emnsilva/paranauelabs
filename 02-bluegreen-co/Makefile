# Variáveis de ambiente (IPs atualizados conforme o seu log)
IP_CP ?= 192.168.122.244
IP_W1 ?= 192.168.122.235
IP_W2 ?= 192.168.122.100

# Caminhos dos scripts
SCRIPTS_DIR = infra/scripts
PREPARE = $(SCRIPTS_DIR)/prepare-kernel.sh
INSTALL = $(SCRIPTS_DIR)/installparanaue.sh
UNINSTALL = $(SCRIPTS_DIR)/uninstallparanaue.sh

.PHONY: lab-up lab-down status ssh-cp ssh-w1 ssh-w2

lab-up:
	@echo "🚀 Iniciando o laboratório BlueGreen Co... (Usuário: alpine)"
	virsh start controlplane 2>/dev/null || true
	virsh start worker1 2>/dev/null || true
	virsh start worker2 2>/dev/null || true
	@echo "⏳ Aguardando SSH responder..."
	@for ip in $(IP_CP) $(IP_W1) $(IP_W2); do \
		echo "Testando $$ip..."; \
		until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 alpine@$$ip "true" 2>/dev/null; do sleep 3; done; \
	done
	@echo "⚙️  Preparando kernel e cgroups..."
	ssh alpine@$(IP_CP) 'sudo sh -s' < $(PREPARE)
	ssh alpine@$(IP_W1) 'sudo sh -s' < $(PREPARE)
	ssh alpine@$(IP_W2) 'sudo sh -s' < $(PREPARE)
	@echo "🎛️  Instalando Control Plane (se necessário)..."
	ssh alpine@$(IP_CP) 'sudo sh -s server' < $(INSTALL)
	@echo "🔑 Obtendo token..."
	@TOKEN=$$(ssh alpine@$(IP_CP) "sudo cat /var/lib/rancher/k3s/server/node-token"); \
	echo "🎛️  Instalando Workers..."; \
	ssh alpine@$(IP_W1) "sudo sh -s agent $(IP_CP) $$TOKEN" < $(INSTALL); \
	ssh alpine@$(IP_W2) "sudo sh -s agent $(IP_CP) $$TOKEN" < $(INSTALL)
	@echo "📝 Configurando kubeconfig no host..."
	@mkdir -p ~/.kube
	@ssh alpine@$(IP_CP) "sudo cat /etc/rancher/k3s/k3s.yaml" | sed "s/127.0.0.1/$(IP_CP)/g" > ~/.kube/config-bluegreen
	@echo "✅ Lab no ar! Rode 'export KUBECONFIG=~/.kube/config-bluegreen' e depois 'make status'."

lab-down:
	@echo "🛑 Desligando o laboratório e limpando o k3s..."
	@for ip in $(IP_CP) $(IP_W1) $(IP_W2); do \
		echo "Limpando $$ip..."; \
		ssh alpine@$$ip 'sudo sh -s' < $(UNINSTALL) || true; \
		ssh alpine@$$ip "sudo poweroff" || true; \
	done
	@echo "😴 VMs desligadas e ambiente limpo."

status:
	@echo "📊 Status dos nós do cluster:"
	@ssh alpine@$(IP_CP) "sudo k3s kubectl get nodes -o wide"

ssh-cp: ; ssh alpine@$(IP_CP)
ssh-w1: ; ssh alpine@$(IP_W1)
ssh-w2: ; ssh alpine@$(IP_W2)