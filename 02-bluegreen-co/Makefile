# Variáveis de ambiente (IPs estáticos atualizados)
IP_CP ?= 192.168.122.122
IP_W1 ?= 192.168.122.126
IP_W2 ?= 192.168.122.161

# Caminhos dos scripts
SCRIPTS_DIR = infra/scripts
PREPARE = $(SCRIPTS_DIR)/prepare-kernel.sh
INSTALL = $(SCRIPTS_DIR)/installparanaue.sh
UNINSTALL = $(SCRIPTS_DIR)/uninstallparanaue.sh
ARGOCD = $(SCRIPTS_DIR)/installargocd.sh
INGRESS = $(SCRIPTS_DIR)/install-ingress-certmanager.sh

# Declaração de todos os alvos para o Make não confundir com arquivos/pastas reais
.PHONY: installparanaue setup-ssh lab-up uninstallparanaue status apply-base bootstrap-argocd bootstrap-ingress argocd-password ssh-cp ssh-w1 ssh-w2

installparanaue:
	@echo "🚀 Iniciando o bootstrap COMPLETO do laboratório..."
	$(MAKE) setup-ssh
	$(MAKE) lab-up
	$(MAKE) apply-base
	$(MAKE) bootstrap-argocd
	$(MAKE) bootstrap-ingress
	@echo "🎉 Tudo pronto! Acesse o Argo CD em https://$(IP_CP):30443"

setup-ssh:
	@echo "🔑 Configurando SSH e Sudo sem senha (vai pedir a senha de cada VM)..."
	for ip in $(IP_CP) $(IP_W1) $(IP_W2); do \
		echo ">>> Configurando $$ip <<<"; \
		ssh-copy-id alpine@$$ip; \
		ssh -t alpine@$$ip "echo 'alpine ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/alpine > /dev/null && sudo chmod 0440 /etc/sudoers.d/alpine"; \
	done
	@echo "✅ Pronto! O 'make lab-up' agora rodará sem senhas."

lab-up:
	@echo "🚀 Iniciando o laboratório BlueGreen Co..."
	@echo "⏳ Verificando conectividade SSH..."
	@for ip in $(IP_CP) $(IP_W1) $(IP_W2); do \
		until ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 alpine@$$ip "true" 2>/dev/null; do sleep 2; done; \
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
	@echo "✅ Lab no ar! Use 'make status' para ver os nós."

uninstallparanaue:
	@echo "🛑 Limpando o laboratório..."
	@for ip in $(IP_CP) $(IP_W1) $(IP_W2); do \
		echo "Limpando $$ip..."; \
		ssh alpine@$$ip 'sudo sh -s' < $(UNINSTALL) || true; \
		ssh alpine@$$ip "sudo reboot" || true; \
	done
	@echo "😴 VMs reiniciadas e ambiente limpo."

status:
	@echo "📊 Status dos nós do cluster:"
	@ssh alpine@$(IP_CP) "sudo k3s kubectl get nodes -o wide"

apply-base:
	@echo "📦 Aplicando namespaces, limites e quotas..."
	cat cluster/namespaces/namespaces.yaml | ssh alpine@$(IP_CP) "sudo k3s kubectl apply -f -"
	cat cluster/namespaces/limitranges.yaml | ssh alpine@$(IP_CP) "sudo k3s kubectl apply -f -"
	cat cluster/namespaces/resourcequotas.yaml | ssh alpine@$(IP_CP) "sudo k3s kubectl apply -f -"
	@echo "✅ Base de namespaces e cotas aplicada!"

bootstrap-argocd:
	@echo "🚀 Instalando Argo CD..."
	ssh alpine@$(IP_CP) 'sudo sh -s' < $(ARGOCD)

bootstrap-ingress:
	@echo "🚀 Instalando Ingress-Nginx e Cert-Manager..."
	ssh alpine@$(IP_CP) 'sudo sh -s' < $(INGRESS)
	@echo "📜 Aplicando ClusterIssuer..."
	cat cluster/namespaces/clusterissuer.yaml | ssh alpine@$(IP_CP) "sudo k3s kubectl apply -f -"
	@echo "✅ Ingress e Cert-Manager instalados!"

argocd-password:
	@echo "🔑 Senha inicial do Argo CD:"
	@ssh alpine@$(IP_CP) "sudo k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"

ssh-cp: ; ssh alpine@$(IP_CP)
ssh-w1: ; ssh alpine@$(IP_W1)
ssh-w2: ; ssh alpine@$(IP_W2)