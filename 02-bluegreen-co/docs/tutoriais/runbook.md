
Este documento descreve os procedimentos operacionais padrão (POPs) para gerenciar o ciclo de vida das aplicações no cluster via Argo CD.

## 1. Acesso e Autenticação
- **URL de Acesso:** `https://192.168.122.122:30443` (NodePort configurado no Control Plane).
- **Usuário:** `admin`
- **Obtenção de Senha:** A senha inicial é gerada dinamicamente e armazenada no secret `argocd-initial-admin-secret`. Para obtê-la via terminal no host, execute: `make argocd-password`.
- **Aviso de SSL:** O certificado é autoassinado. Aceite o aviso de segurança no navegador.

## 2. Fluxo de Trabalho GitOps (App-of-Apps)
O cluster não é alterado via `kubectl apply` ou `helm install` manual. A fonte da verdade é o repositório Git.
1. Altere o manifesto YAML no repositório local.
2. Faça o `git commit` e `git push`.
3. O Argo CD detecta a alteração (polling de 3 minutos) ou clique em **REFRESH** na UI.
4. O Argo CD reconcilia o cluster com o estado do Git (política `selfHeal: true` ativada).

## 3. Sincronização Manual e Forçada
Caso o estado do cluster divirja do Git (ex: alguém fez um `kubectl edit` manual), o Argo CD marcará o app como `OutOfSync`.
- **Via UI:** Clique no botão **SYNC** no card da aplicação afetada.
- **Via CLI (dentro da VM):** `sudo k3s kubectl -n argocd patch application <nome-do-app> --type merge -p '{"operation":{"sync":{}}}'`

## 4. Operações de Rollback
Se um commit quebrou o cluster e a sincronização automática aplicou a falha:
- **Via UI:** Abra o app no Argo CD > clique em **HISTORY AND ROLLBACK** > selecione a revisão anterior (commit do Git) > clique em **ROLLBACK**.
- **Atenção:** O Argo CD reverterá os manifestos para o estado anterior do Git, mas não fará *rollback* de dados em bancos de dados (isso é responsabilidade da aplicação).

## 5. Adicionando um Novo Componente ao Cluster
Para instalar algo novo (ex: Prometheus):
1. Crie um novo arquivo YAML de `Application` na pasta `02-bluegreen-co/cluster/apps/children/`.
2. Faça commit e push.
3. O `root-app` (aplicação raiz) vai ler a pasta, ver o novo arquivo e criar o card da nova aplicação automaticamente.

## 6. Troubleshooting Comum
- **Erro `ComparisonError`:** O Argo CD não conseguiu ler o repositório. Verifique se o repositório está público ou se as credenciais (se privado) estão corretas em *Settings > Repositories*.
- **App travado em `Progressing`:** O Kubernetes não consegue agendar os pods por falta de recursos (CPU/RAM). Verifique as `ResourceQuotas` do namespace e os eventos do cluster.
- **UI Inacessível:** Verifique se os pods do `argocd-server` estão rodando e se a porta 30443 não foi bloqueada por firewall no host.