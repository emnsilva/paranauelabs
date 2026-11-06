## 1. Contexto da R2
A R2 tinha como objetivo transformar o cluster em um ambiente GitOps, tirando o controle manual e passando a gestão para o Argo CD. A expectativa era instalar os componentes base e criar a estrutura de aplicações filhas (App-of-Apps) de forma fluida. No entanto, o ambiente restrito (hardware) e a interação entre os componentes exigiram um esforço maior do que o planejado, especialmente na gestão de memória e conflitos de rede.

## 2. O que funcionou
- **A transição para GitOps:** O padrão App-of-Apps funcionou perfeitamente. Após a aplicação do root-app, o Argo CD sincronizou automaticamente os componentes filhos. O conceito de self-healing foi comprovado quando o Argo CD corrigiu estados divergentes sozinho.
- **O isolamento de namespaces:** As cotas e limites que criamos (mesmo que inicialmente apertadas) provaram seu valor ao evitar que o cluster inteiro caísse por falta de memória no host.
- **O padrão de nomenclatura:** O uso de scripts installparanaue e uninstallparanaue manteve a consistência e a automação via Makefile.


## 3. O que não funcionou (ou deu trabalho)
- **Subdimensionamento de recursos:** O Argo CD falhou repetidamente ao subir (exceeded quota). O LimitRange e o ResourceQuota iniciais eram pequenos demais para a quantidade de componentes que o Argo CD roda por padrão.
- **Conflito de Portas (NodePort):** Tentamos expor o Argo CD e o Ingress-Nginx usando a mesma porta (30443). O Kubernetes bloqueou a criação e foi necessário remapear o Ingress para portas alternativas (30081/30444).
- **Dependências ocultas:** O Cert-Manager travou no Helm por causa do job de verificação (startupapicheck), que não foi finalizado dentro do tempo limite (timeout).
- **Recriação de VMs e perda de estado:** A recriação das VMs apagou as chaves SSH e os binários offline, forçando um retrabalho na configuração de acesso e na instalação do k3s.
- **O Makefile e a armadilha do .PHONY:** O comando make ignorou os alvos de instalação porque achou que já haviam sido executados (falta da declaração .PHONY).

## 4. O que aprendemos
- **O Argo CD é "pesado" para um lab:** Um cluster k3s de lab precisa desabilitar componentes não utilizados do Argo CD (Dex, Notifications, ApplicationSet) para caber em restrições de memória.
- **Cotas de memória devem ter margem:** Definir cotas muito justas baseadas apenas em "estimativas" causa falhas silenciosas. É melhor superdimensionar a cota do namespace e confiar no LimitRange para conter pods individuais.
- **Mapeamento de portas é crítico:** Em ambientes locais (NodePort), o planejamento das portas de cada componente precisa ser feito antes da instalação, mapeando o que o k3s já usa e o que o Argo/Ingress vão precisar.
- **Git é a fonte da verdade, inclusive para desfazer:** Recuperar um arquivo commitado que estava funcionando foi a forma mais rápida de resolver o problema do Helm, em vez de tentar debugar o erro no calor do momento.

## 5. O que faremos diferente na R3 (Aplicação v1)
- **Dimensionamento prévio:** Antes de fazer o deploy da aplicação bgapp, vamos calcular a soma de requests e limits dos containers e garantir que isso não estoura a ResourceQuota do namespace bluegreen.
- **Teste local primeiro:** O Dockerfile e as migrações serão testados localmente (fora do cluster) antes de fazer o push no GitOps, para evitar que erros de build derrubem o fluxo do Argo CD.
- **Validação de Manifests:** Usar kubectl apply --dry-run=client ou o próprio Argo CD localmente para validar a sintaxe dos YAMLs da aplicação antes de commitar.

## 6. Impacto no backlog
- **Adição de um card de Observabilidade:** A falta de visibilidade sobre o consumo de memória (que causou os erros de cota) mostrou a necessidade de instalar o Prometheus e o Grafana o quanto antes. Isso foi movido para a R4.
- **Ajuste de estimativas:** O tamanho das atividades relacionadas ao Argo CD estava subestimado. Para a R3, cards que envolvem a aplicação e o banco de dados (CloudNativePG) devem ser tratados com mais margem de tempo e recurso.