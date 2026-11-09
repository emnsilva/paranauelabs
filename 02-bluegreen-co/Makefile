# Variáveis de ambiente (IPs estáticos)
IP_CP ?= 192.168.122.122
IP_W1 ?= 192.168.122.126
IP_W2 ?= 192.168.122.161

# Caminhos dos scripts
SCRIPTS_DIR = infra/scripts
PREPARE = $(SCRIPTS_DIR)/prepare-kernel.sh
INSTALL = $(SCRIPTS_DIR)/installparanaue.sh
UNINSTALL = $(SCRIPTS_DIR)/uninstallparanaue.sh
ARGOCD = $(SCRIPTS_DIR)/installargocd.sh

.PHONY: installparanaue setup-ssh lab-up uninstallparanaue status apply-base bootstrap-argocd wait-argocd bootstrap-gitops argocd-password ssh-cp ssh-w1 ssh-w2

installparanaue:
	@echo "🚀 Iniciando o bootstrap COMPLETO do laboratório..."
	$(MAKE) lab-up
	$(MAKE) apply-base
	$(MAKE) bootstrap-argocd
	$(MAKE) wait-argocd
	$(MAKE) bootstrap-gitops
	@echo "🎉 Tudo pronto! O Argo CD está sincronizando o cluster."
	@echo "Acesse: https://$(IP_CP):30443"

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

apply-base:
	@echo "📦 Aplicando namespaces, limites e quotas..."
	cat cluster/namespaces/namespaces.yaml | ssh alpine@$(IP_CP) "sudo k3s kubectl apply -f -"
	cat cluster/namespaces/limitranges.yaml | ssh alpine@$(IP_CP) "sudo k3s kubectl apply -f -"
	cat cluster/namespaces/resourcequotas.yaml | ssh alpine@$(IP_CP) "sudo k3s kubectl apply -f -"
	@echo "✅ Base de namespaces e cotas aplicada!"

bootstrap-argocd:
	@echo "🚀 Instalando Argo CD..."
	ssh alpine@$(IP_CP) 'sudo sh -s' < $(ARGOCD)

wait-argocd:
	@echo "⏳ Aguardando a VM respirar e o Argo CD subir (isso pode levar 2 minutos)..."
	@sleep 30
	@echo "Verificando se os pods do Argo CD estão prontos..."
	@ssh alpine@$(IP_CP) "sudo k3s kubectl wait --for=condition=available deployment/argocd-server -n argocd --timeout=180s" || true

bootstrap-gitops:
	@echo "🔄 Aplicando a aplicação raiz (root-app) para iniciar o GitOps..."
	cat cluster/apps/root-app.yaml | ssh alpine@$(IP_CP) "sudo k3s kubectl apply -f -"
	@echo "✅ Root-app aplicada! O Argo CD agora gerenciará o Ingress, Cert-Manager, Banco, etc."

argocd-password:
	@echo "🔑 Senha inicial do Argo CD:"
	@ssh alpine@$(IP_CP) "sudo k3s kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' | base64 -d; echo"

ssh-cp: ; ssh alpine@$(IP_CP)
ssh-w1: ; ssh alpine@$(IP_W1)
ssh-w2: ; ssh alpine@$(IP_W2)