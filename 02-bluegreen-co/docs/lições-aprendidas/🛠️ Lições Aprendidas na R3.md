# Retrospectiva: Release 3 (Publicar aplicação v1)

**Data:** 13-11-2026
**Release:** R3 - `v1.0.0-beta.1`
**Foco:** Deploy da aplicação v1, provisionamento do banco de dados e configuração de Ingress/TLS.

## 1. Contexto da R3
A R3 tinha como objetivo colocar a aplicação no ar, garantindo persistência de dados e acesso externo via HTTPS. A expectativa era usar o CloudNativePG para o banco e o Cert-Manager para os certificados. No entanto, a incompatibilidade do operador com o k3s e falhas no bootstrap de recursos exigiram uma mudança de rota e ajustes finos de infraestrutura.

## 2. O que funcionou
- **O Pivô para StatefulSet:** A decisão de abandonar o operador e usar um StatefulSet nativo foi certeira. O banco subiu em segundos, sem erros de webhook e com persistência garantida.
- **Migração via Kubernetes Job:** Rodar o script SQL (`01_expand.sql`) através de um Job do Kubernetes foi uma solução elegante, isolada e 100% GitOps.
- **TLS via Ingress:** O redirecionamento HTTP para HTTPS e a emissão do certificado autoassinado funcionaram perfeitamente, garantindo a segurança do acesso.
- **Validação com `curl`:** A prova real do deploy via linha de comando (`HTTP/2 200` com o payload correto) trouxe segurança para avançar.

## 3. O que não funcionou (ou deu trabalho)
- **CloudNativePG (CNPG):** O operador entrou em loop infinito de `CrashLoopBackOff` (falhas de webhook e certificados), provando ser "overkill" para as restrições de memória do lab.
- **Cotas do Cert-Manager:** O webhook do cert-manager não subia porque estourava as `ResourceQuotas` (precisamos aumentar a cota e ajustar os limites de CPU/Memória).
- **ClusterIssuer ausente:** Ao desmontar o lab, o `ClusterIssuer` não foi recriado pelo Makefile, travando a emissão do certificado TLS do Ingress.
- **Portas do Ingress:** Esquecemos que o Ingress-Nginx foi exposto na porta NodePort `30444` em vez da porta padrão `443`, o que gerou confusão no primeiro teste com `curl`.

## 4. O que aprendemos
- **Operadores pesados não são para labs:** Ferramentas feitas para grandes nuvens (como o CNPG) adicionam complexidade e instabilidade em ambientes minimalistas (k3s/Alpine).
- **Bootstrap precisa ser atômico:** Tudo o que é necessário para o funcionamento básico (Namespaces, Cotas, ClusterIssuers) deve ser inserido no `make apply-base` ou no bootstrap do GitOps. Se não está no Git ou no Makefile, não existe.
- **Testes de rede exigem atenção:** Quando usamos NodePorts customizados, o teste local (curl) precisa sempre incluir a porta (`:30444`).

## 5. O que faremos diferente na R4 (Automação de CI)
- **Testar o pipeline no Git:** Em vez de buildar imagens manualmente ou com scripts locais, a R4 vai focar em fazer o GitHub Actions cuidar de tudo (build, scan e commit no GitOps).
- **Revisão de cotas:** O CI vai construir imagens, mas o Argo CD vai atualizar as tags. O monitoramento de memória continuará sendo crucial para não derrubar o cluster.

## 6. Impacto no backlog
- **Adição de dependências de bootstrap:** O `Makefile` foi atualizado para garantir a criação do `ClusterIssuer`.
- **ADR-005 atualizado:** Substituído pelo ADR-007 (StatefulSet), documentando a mudança de arquitetura.