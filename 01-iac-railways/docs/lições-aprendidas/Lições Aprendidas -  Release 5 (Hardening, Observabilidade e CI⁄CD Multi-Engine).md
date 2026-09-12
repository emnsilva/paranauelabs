Nesta release final, expandi a esteira para incluir Jenkins (além do GitHub Actions), implementei Análise Estática (SAST) com tfsec e criei pipelines de auditoria de Drift em paralelo. Os desafios foram intensos no nível de infraestrutura local e concorrência de processos.

## 1. O tfsec não ignora regras se o comentário estiver dentro do bloco
**O que aconteceu:** Tentei silenciar alertas do tfsec (ex: liberação de porta 80 para a internet) colocando o comentário # tfsec:ignore:... logo acima do atributo cidr_blocks. O tfsec continuava falhando a esteira.<br>
**A causa:** O tfsec avalia regras de segurança em dois níveis: no nível do atributo (ex: cidr_blocks) e no nível do recurso inteiro (ex: aws_security_group ou aws_vpc). Para regras que avaliam o recurso inteiro (como Flow Logs ou S3 Logging), o comentário de ignore deve ficar na linha exatamente acima da palavra resource.<br>
**A solução:** Movi todos os comentários # tfsec:ignore para a linha imediatamente anterior à declaração do resource. Isso garantiu que o tfsec silenciasse as regras corretamente para o bloco inteiro.

## 2. Jenkins em container Docker local e o problema do IPv6
**O que aconteceu:** Subi o Jenkins em um container Docker na minha VM Alpine local. Ao tentar rodar a esteira usando agent { docker { image 'hashicorp/terraform' } }, o Jenkins falhava ao baixar a imagem do Docker Hub com o erro network is unreachable e endereços IPv6.<br>
**A causa:** A rede da minha VM local não tinha roteamento IPv6 completo, mas o Docker e o Jenkins insistiam em resolver os domínios do Docker Hub (auth.docker.io) para IPv6.<br>
**A solução:** Em vez de gastar tempo configurando rotas IPv6 ou desativando o IPv6 no host, tomei a decisão arquitetural de mudar o Jenkinsfile para agent any e instalei os binários do Terraform, OpenTofu e tfsec diretamente dentro do container do Jenkins. Isso eliminou a necessidade de "Docker-inside-Docker" (DinD) e resolveu todos os problemas de rede, tornando a esteira mais rápida e leve.

## 3. Race Condition na matriz do Jenkins
**O que aconteceu:** Criei um Jenkinsfile.drift que usava a instrução matrix para rodar 24 jobs de auditoria em paralelo. Vários jobs falhavam dizendo que não encontravam o workspace prod_oci_tfc, mesmo os jobs que eram da AWS ou Azure.<br>
**A causa:** DNo Jenkins, variáveis definidas usando env.VARIAVEL = "valor" dentro de um script são globais para a build. Quando 24 jobs rodavam em paralelo, eles tentavam escrever na mesma variável env.TF_WORKSPACE ao mesmo tempo. O último que escrevesse "ganhava", e todos os outros liam o valor errado.<br>
**A solução:** Troquei a definição de variáveis globais (env.) por variáveis locais (def) dentro do script do pipeline. Em seguida, usei o bloco withEnv([...]) para injetar essas variáveis locais no ambiente do shell APENAS para aquele step específico. Isso garantiu o isolamento de cada um dos 24 jobs paralelos.

## 4. Arte de Diagramas em ASCII vs Mermaid
**O que aconteceu:**  Inicialmente desenhei a arquitetura de rede e de CI/CD usando blocos de código Mermaid.js no README.<br>
**A solução:** Decidi refatorar para arte ASCII (desenhos usando caracteres de texto). O motivo é que o ASCII não depende de renderização JavaScript para ser visualizado (funciona perfeitamente em terminais, no cat do Linux, ou em editores de texto simples). Isso deu um charme "old-school" de engenharia de software ao portfólio e eliminou a dependência de renderização do GitHub/GitLab.