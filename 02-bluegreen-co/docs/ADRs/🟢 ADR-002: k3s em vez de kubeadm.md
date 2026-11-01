Número do ADR: 002
Data: 01-11-2026
Responsável: Equipe SRE/DevOps - Lab Blue/Green
Status: 🟢 Aceito

## Contexto
O laboratório exige um cluster Kubernetes funcional rodando sobre 3 VMs Alpine Linux com recursos restritos (1 control plane com 2 GB de RAM e 2 workers com 3 GB cada). O Alpine Linux é uma distribuição minimalista que utiliza a biblioteca musl em vez da glibc, e o gerenciador de serviços OpenRC em vez do systemd.

O problema central é: qual distribuição Kubernetes permite uma instalação limpa no Alpine, sem quebrar as restrições de memória e sem exigir camadas de compatibilidade complexas?

O candidato padrão de mercado é o kubeadm, mas ele foi projetado assumindo um ambiente com glibc e systemd. O candidato alternativo é o k3s, uma distribuição leve e empacotada em um único binário. Antes de decidir, executamos o spike de pesquisa (card 1.1) para responder a três perguntas com dados:

1- O kubeadm roda no Alpine sem a camada gcompat?
2- O k3s integra-se nativamente ao OpenRC sem scripts customizados?
3- Qual o footprint real de memória de cada opção no control plane de 2 GB?

## Decisão
Adotar o k3s v1.36.x como a distribuição Kubernetes oficial do laboratório. A instalação é feita via script oficial (get.k3s.io), que detecta o OpenRC automaticamente e cria o serviço de inicialização sem intervenção manual. A troca não afeta a aplicação (que continua sendo um manifesto Kubernetes padrão) nem os scripts de automação (Makefile).

A implementação seguirá este desenho:

- Instalação via script oficial: curl -sfL https://get.k3s.io | sh - (server) e curl -sfL https://get.k3s.io | K3S_URL=... K3S_TOKEN=... sh - (agent).
- Datastore: SQLite embarcado (padrão do k3s para single-node control plane), eliminando a necessidade de gerenciar um cluster etcd separado em um ambiente com restrição de RAM.
- Runtime: containerd embutido (sem necessidade de instalar Docker ou configurar CRI manualmente).
- Token de junção: Gerenciado e capturado automaticamente pelo Makefile (lab-up), sem armazenamento manual de segredos.

## Justificativa
- **Compatibilidade nativa com musl:** O k3s é um binário estático compilado em Go. Ele não depende de glibc, eliminando a necessidade de instalar gcompat ou libc6-compat no Alpine — camada que, no kubeadm, vira um ponto de falha silenciosa.
- **Integração com OpenRC:** O instalador oficial do k3s detecta o OpenRC e cria o serviço /etc/init.d/k3s automaticamente. No kubeadm, seria necessário escrever o script de inicialização manualmente e gerenciar o containerd de forma independente.
- **Footprint de memória:** O k3s server consome cerca de 1,6 GB em repouso com carga leve. O kubeadm (com kube-apiserver, etcd, kube-controller-manager e kube-scheduler separados) consome cerca de 1,5 GB apenas para os componentes de controle, sem contar o containerd e o SO — o que inviabiliza o control plane de 2 GB.
- **Menor complexidade operacional:** Um único binário instala server, agent, kubectl, crictl e ctr. O kubeadm exige a instalação e configuração de múltiplos binários (kubeadm, kubelet, kubectl, containerd, runc, cni-plugins).
- **Conformidade com CNCF:** O k3s é um Kubernetes certificado pela CNCF. Tudo o que funciona em um cluster kubeadm (Deployments, Services, Ingress, CRDs) funciona no k3s sem alteração.

## Alternativas consideradas
**Alternativa 1:** kubeadm sobre Alpine 3.23.7<br>
Descrição: usar o instalador padrão do Kubernetes, com configuração manual de containerd e cni-plugins.<br>

**Por que foi descartada?**
- **Dependência de glibc:** O kubeadm exige glibc; sobre Alpine, isso significa instalar gcompat/libc6-compat, adicionando uma camada de compatibilidade que pode quebrar de formas sutis (ex: resolução de DNS, chamadas de sistema).
- **Dependência de systemd:** O kubeadm usa systemctl para gerenciar o kubelet; sobre OpenRC, seria necessário escrever scripts de inicialização customizados e conviver com logs dispersos.
- **Footprint maior:** A soma de kube-apiserver + etcd + kube-controller-manager + kube-scheduler + containerd consome mais RAM do que o control plane de 2 GB pode suportar com folga.

**Alternativa 2:** MicroK8s sobre Alpine<br>
Descrição: usar a distribuição MicroK8s da Canonical.<br>

**Por que foi descartada?**
- **Dependência de snap:** O MicroK8s é instalado exclusivamente via snap, que não está disponível no Alpine.
- **Dependência de systemd:** O mesmo problema do kubeadm, mas agravado pelo fato de o MicroK8s assumir systemd em toda a sua lógica de inicialização.

**Alternativa 3:** kind (Kubernetes in Docker) sobre Alpine<br>
Descrição: rodar um cluster kind dentro das VMs Alpine.<br>

**Por que foi descartada?**
- **Conflito de cgroups:** O kind usa Docker-in-Docker (DinD), que no Alpine apresenta falhas conhecidas de inicialização de control plane e de plugin de rede (cgroups v2 e namespaces).
- **Overhead duplo:** O cluster rodaria dentro de containers, consumindo mais RAM do que a alocação direta no host. Contraria o objetivo de otimização de memória.

## Consequências

| POSITIVAS | NEGATIVAS/DESAFIOS |
|---|---|
| **Instalação de um comando:** server e agent instalam em menos de 30 segundos, sem necessidade de configurar containerd, CNI ou etcd. | **Tutoriais de mercado assumem kubeadm:** Alguns tutoriais de Kubernetes assumem que você tem kubeadm disponível. Adaptar exemplos é trivial, mas requer atenção. |
| **Integração nativa com OpenRC:** O serviço reinicia automaticamente após reboot, sem script customizado. | **Menos "vanilla":** Alguns componentes (como o etcd) são substituídos por padrões do k3s (SQLite). Para o lab, isso é uma vantagem; para um ambiente de produção que exija etcd separado, seria uma limitação. |
| **Footprint de memória compatível com 2 GB:** O server ocupa ~1,6 GB, deixando margem para a stack de GitOps e observabilidade. | **Dependência do instalador oficial:** Atualizações do k3s são feitas via script ou system-upgrade-controller, não via apt upgrade. O processo é documentado e gerenciado pelo Makefile do lab. |
| **Tudo em um binário:** kubectl, crictl e ctr já vêm instalados, eliminando etapas de configuração. | **Menor familiaridade para iniciantes:** Quem nunca usou k3s pode estranhar o caminho /etc/rancher/k3s/k3s.yaml em vez do padrão ~/.kube/config. O Makefile resolve isso via kubectl config. |
| **Conformidade CNCF:** Os manifests da aplicação (Deployments, Services, Ingress) são idênticos aos de um cluster kubeadm. | — |

## Mitigações
- **Tutoriais adaptados:** O docs/runbook.md e o docs/tutoriais/provisionamento-do-lab.md documentam os comandos específicos do k3s (ex: sudo k3s kubectl em vez de kubectl).
- **Atualização controlada:** A versão do k3s é fixada no installparanaue.sh (INSTALL_K3S_VERSION). Atualizações são feitas via make lab-up (que reinstala na versão pinada) ou via script de upgrade documentado.
- **Portabilidade:** Se o lab migrar para uma nuvem gerenciada (EKS/GKE/AKS), os manifests e o Makefile funcionam sem alteração; apenas o método de instalação do cluster muda (que deixa de ser responsabilidade do lab).

## Registro de mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por… |
|---|---|---|---|---|
| 01-11-2026 | Primeira versão | Documentar a decisão de adotar k3s em vez de kubeadm, sustentada pelo spike do card 680 |Reduz o footprint de memória, elimina dependência de glibc/systemd e simplifica a instalação no Alpine | Emershow |