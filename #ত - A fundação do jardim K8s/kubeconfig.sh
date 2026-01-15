# Configura o kubectl
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Instala o plugin de rede:
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml
