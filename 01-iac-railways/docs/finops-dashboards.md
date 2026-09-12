## 📊 Runbook de FinOps e Observabilidade de Custos
Este documento descreve como visualizar e auditar os custos da infraestrutura do laboratório IaC Railways em cada provedor de nuvem.

Todos os recursos provisionados via Terraform/OpenTofu nascem com as seguintes tags obrigatórias (definidas no bloco default_tags):

- **Project:** paranauelabs
- **Environment:** dev, staging ou prod
- **Owner:** emershow
- **CostCenter:** sre (ou minúsculas no GCP/Oracle devido a restrições de plataforma)

---

#### 1. AWS (Amazon Web Services)
**Onde acessar:**
1. Faça login no Console da AWS.
2. Procure por Cost Explorer (ou Billing and Cost Management > Cost Explorer).
3. Clique em Launch Cost Explorer.

**Como visualizar:**
1. No painel esquerdo, em Group by, selecione Tag.
2. Escolha a tag Project ou Environment.
3. Filtre por Project = paranauelabs para ver apenas os custos deste laboratório.
4. Você também pode ver os alertas de orçamento (Budgets) criados via Terraform indo em Budgets no menu de Billing.

---

#### 2. Azure (Microsoft Azure)
*Nota: Para que as tags apareçam no Cost Management, a opção "Tag inheritance" deve estar ativada nas configurações de Cost Management da assinatura.*

**Onde acessar:**
1. Faça login no Portal do Azure.
2. Procure por Cost Management + Billing.
3. Selecione Cost analysis no menu lateral.

**Como visualizar:**
1. Clique em Add filter.
2. Selecione Tag e escolha Project (ou Environment).
3. Selecione o valor paranauelabs.
4. Para ver os alertas de orçamento criados via Terraform, vá em Budgets no menu lateral de Cost Management.

---

#### 3. GCP (Google Cloud Platform)
*Nota: No GCP, as tags são chamadas de "Labels". O GCP exige que as chaves dos labels sejam em letras minúsculas (ex: project, environment).*

**Onde acessar:**
1. Faça login no Console do GCP.
2. Abra o menu de navegação e vá em Billing.
3. Clique em Reports (Relatórios).

**Como visualizar:**
1. No painel de filtros (lado direito), em Group by, selecione Labels.
2. Escolha o label project ou environment.
3. Os custos serão agrupados e exibidos no gráfico de barras.

---

#### 4. Oracle Cloud Infrastructure (OCI)
*Nota: A OCI requer que os relatórios de custo sejam habilitados no nível da Tenancy para que as tags apareçam nos gráficos.*

**Onde acessar:**
1. Faça login no Console da OCI.
2. Abra o menu de navegação e vá em Billing & Cost Management.
3. Clique em Cost Analysis (Análise de custos).

**Como visualizar:**
1. No painel de filtros, em Dimensions, selecione Free-form Tag Key (ou Tag Namespace se estiver usando tags definidas).
2. Escolha a tag project ou environment.
3. Clique em Update para gerar o gráfico de custos agrupado por ambiente.