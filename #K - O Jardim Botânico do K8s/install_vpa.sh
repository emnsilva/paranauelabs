# Script de instalação do VPA (Vertical Pod Autoscaler)
echo "Iniciando instalação do VPA..."

# Clone o repositório oficial
git clone https://github.com/kubernetes/autoscaler.git

# Navegue para o diretório do VPA
cd autoscaler/vertical-pod-autoscaler/

# Aplique os componentes do VPA
./hack/vpa-up.sh

echo "Instalação do VPA concluída!"