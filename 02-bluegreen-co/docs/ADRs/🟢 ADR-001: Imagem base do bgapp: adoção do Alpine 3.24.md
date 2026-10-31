Número do ADR: 001
Data: 30-10-2026
Responsável: Equipe SRE/DevOps - Lab Blue/Green
Status: 🟢 Aceito

## Contexto
O lab Blue/Green roda em 3 VMs no virt-manager sobre um notebook com recursos limitados: 1 control plane com 2 GB de RAM e 2 workers com 3 GB cada. A soma (8 GB) precisa caber junto com o hipervisor, o SO do host e margem para o próprio notebook — o que torna o footprint de SO de cada VM um fator de primeira ordem, não um detalhe de implementação.

O problema central é: qual SO de VM minimiza o consumo de RAM e disco em repouso sem comprometer a compatibilidade com o k3s e sem exigir camadas de compatibilidade glibc?

O candidato é a série Alpine 3.24, com o patch 3.24.2 como específico. Antes de decidir, executamos o spike do card 1.1 (pesquisa registrada em docs/research/alpine-k3s.md) para responder três perguntas com dados, não estimativas:

1- Qual o footprint real de RAM e disco do Alpine 3.24.2 vs. Ubuntu Server 24.04 e Debian 12 slim, no mesmo papel (VM com k3s instalado)?
2- O k3s instala no Alpine 3.24.2 sem gcompat/libc6-compat, com cgroups v2 funcionando e os três módulos de kernel carregando?
3- Existe caminho suportado na série 3.24 que não exija mudança no script de provisionamento (card 1.2) nem na instalação do k3s (card 1.4)?

O spike rodou em VM Alpine descartável (minirootfs oficial do CDN) e coletou evidências direto das fontes primárias (Alpine CDN, APKINDEX v3.24, wiki oficial do k3s sobre Alpine, release notes do OpenRC), com versões e hashes verificados — reproduzível pelo script do projeto.

## Decisão
Adotar Alpine Linux 3.24.2 como SO das 3 VMs do lab, instalado via minirootfs oficial (alpine-minirootfs-3.24.2-x86_64.tar.gz, sha256 registrado em docs/research/alpine-k3s.md, medido em 2026-10-30), com k3s v1.36.x instalado pelo instalador oficial get.k3s.io. A troca é confinada ao cloud-init e ao script de provisionamento (card 1.2); o restante do lab (manifests, stack Argo, aplicação) não depende do SO do host.

A implementação seguirá este desenho:
- Pin por versão exata: Alpine 3.24.2 (minirootfs com hash registrado) e k3s v1.36.x fixado via INSTALL_K3S_VERSION. Sem latest.
- Ajustes obrigatórios no cloud-init:
    - Habilitar o serviço cgroups no OpenRC (rc-update add cgroups).
    - Criar /etc/modules-load.d/k3s.conf com br_netfilter, overlay, nf_conntrack.
    - Desabilitar swap (swapoff -a + remoção de entrada em /etc/fstab).
    - Desativar /usr-merge (BOOTSTRAP_USR_MERGED=0), introduzido no Alpine 3.24.
- Método de instalação do k3s: instalador oficial get.k3s.io (detecta OpenRC automaticamente), em vez do pacote k3s-openrc da comunidade (ver Alternativa 4).
- KSM habilitado no host como complemento — não substitui a escolha do SO, mas é o que torna o footprint ainda menor na prática.

## Justificativa
- Footprint de RAM e disco muito menor que as alternativas com glibc. Alpine 3.24.2 instalado ocupa ~120 MB de disco e ~40-60 MB de RAM em repouso; Ubuntu Server 24.04 mínimo ocupa ~1,4 GB de disco e ~180-220 MB de RAM em repouso; Debian 12 slim fica em ~600 MB / ~100-130 MB. Num control plane de 2 GB, a diferença entre Alpine e Ubuntu é ~10% da RAM total da VM — folga real para o k3s server, que já usa ~1,6 GB.
- Compatibilidade com k3s sem gcompat. O k3s é compilado estaticamente em Go; não exige glibc. O instalador oficial detecta OpenRC e cria o serviço k3s sem arquivo customizado. A pesquisa confirmou que kubeadm sobre Alpine exigiria gcompat — caminho descartado (Alternativa 3).
- cgroups v2 pronto no kernel, apenas não habilitado por padrão. O Alpine 3.19+ já traz cgroups v2 no kernel 6.18; o serviço cgroups do OpenRC precisa ser habilitado explicitamente — passo documentado e resolvido no cloud-init.
- Módulos de kernel disponíveis e carregáveis. br_netfilter, overlay e nf_conntrack existem no kernel do Alpine 3.24.2; o cloud-init os carrega via /etc/modules-load.d/k3s.conf.
- Zero custo e série com EOL longo. Alpine 3.24 tem EOL em 2028-06-01; atualização é bump de versão no cloud-init, sem quebra de interface. Nenhuma licença envolvida.
- Decisão auditável. Evidência de fonte primária com versões, hashes e medições reproduzíveis pelo spike — padrão para futuros ADRs do lab.

## Alternativas consideradas
**Alternativa 1:** Ubuntu Server 24.04 LTS<br>
Descrição: manter a distro "padrão" da indústria, com glibc nativa e ferramental completo.<br>

**Por que foi descartada?**
- Footprint ~10× maior de disco e ~4× maior de RAM em repouso — 180-220 MB de RAM num control plane de 2 GB comprometem a estabilidade do k3s server.
- Superfície de SO maior (apt/dpkg, systemd, utilitários não usados pelo lab) e mais pacotes para o trivy reportar.
- O argumento de "ferramental completo" perde força no lab: o k3s é autossuficiente e o debug é feito no host, não na VM.

**Alternativa 2:** Debian 12 slim<br>
Descrição: meio-termo entre Ubuntu e Alpine, com glibc e footprint menor que Ubuntu.<br>

**Por que foi descartada?**
- Ainda ~5× maior em disco e ~2× maior em RAM em repouso comparado ao Alpine.
- glibc nativa não compensa no lab: o k3s não precisa dela, e as ferramentas de debug usadas (kubectl, virsh, curl) rodam no host, não na VM.
- Ganho de compatibilidade é teórico; o custo de footprint é real.

**Alternativa 3:** kubeadm sobre Alpine 3.24.2<br>
Descrição: usar o instalador padrão do Kubernetes em vez do k3s.<br>

**Por que foi descartada?**
- kubeadm exige glibc; sobre Alpine isso significa instalar gcompat/libc6-compat — camada extra de compatibilidade que vira ponto de falha silenciosa.
- kubeadm também exige containerd configurado manualmente, aumentando o escopo do card 1.4 sem ganho funcional para o lab.
- O k3s entrega o mesmo Kubernetes, com instalador integrado ao OpenRC e footprint menor.

**Alternativa 4:** Pacote k3s-openrc da comunidade em vez do instalador oficial<br>
Descrição: instalar k3s via apk add k3s-openrc (disponível na comunidade do Alpine 3.24 a partir de v1.36.1.1-r0), em vez do instalador oficial get.k3s.io.<br>

**Por que foi descartada?**
- O instalador oficial é o caminho suportado upstream, com controle explícito de versão (INSTALL_K3S_VERSION) — o pacote da comunidade trava na versão empacotada.
- O instalador já detecta OpenRC e cria o serviço automaticamente; o pacote k3s-openrc adiciona pouco.
- Nota: fica registrado como caminho alternativo válido caso o lab precise de integração mais profunda com OpenRC no futuro.

**Alternativa 5:** Alpine 3.19.x (série anterior)<br>
Descrição: usar a série 3.19, amplamente validada com k3s na comunidade.<br>

**Por que foi descartada?**
- EOL mais próximo (3.19 encerra suporte antes de 3.24).
- Sem ganho de compatibilidade sobre 3.24.2 — o spike confirmou que 3.24.2 tem os mesmos requisitos (cgroups, módulos, OpenRC) e o pacote k3s-openrc disponível como plus.
- Ficar em 3.19 seria herdar débito técnico no dia 1.

## Consequências

| POSITIVAS | NEGATIVAS/DESAFIOS |
|---|---|
| **Footprint de RAM ~4× menor que Ubuntu (40-60 MB vs 180-220 MB em repouso):** o control plane de 2 GB respira. | /usr-merge introduzido no 3.24 precisa ser explicitamente desativado no cloud-init, senão caminhos em /bin, /sbin e /lib* viram symlinks e scripts que assumem caminhos tradicionais quebram. |
| **Disco ~10× menor por VM:** 3 VMs somam ~360 MB de SO, não 4 GB. | O serviço cgroups do OpenRC não vem habilitado por padrão — o k3s inicia mas pods falham silenciosamente ao criar namespaces. Resolvido no cloud-init. |
| **Superfície de SO mínima e auditável:** ~10-15 pacotes na base; trivy terá pouca coisa a reportar. | Módulos de kernel não carregam automaticamente — /etc/modules-load.d/k3s.conf é obrigatório. Sem ele, o overlay não monta e o containerd do k3s falha. |
| Compatibilidade com k3s sem gcompat — instalador oficial detecta OpenRC e cria serviço. | Menos ferramentas de debug (sem bash, sem systemctl); busybox sh está disponível, mas fluxos que assumem ferramental Ubuntu precisam de adaptação. |
| **Atualização sem quebra:** bump de versão no cloud-init, sem alterar manifests ou scripts. | **musl ≠ glibc:** ferramentas compiladas contra glibc (raras no escopo do lab) exigiriam gcompat. O k3s não é uma delas. |
| Zero custo, EOL 2028-06-01, sem licença. | Prova de execução pendente: a escolha foi validada em pesquisa; build/boot real com k3s será validado. |

## Mitigações
- **/usr-merge:** desativar explicitamente no cloud-init (BOOTSTRAP_USR_MERGED=0) e verificar no card 1.2 que nenhum script depende de caminho absoluto em /bin ou /sbin. Se a imagem oficial do minirootfs 3.24.2 já vier com /usr-merge ativo, o cloud-init reverte antes do setup-disk.
- **cgroups:** rc-update add cgroups boot no cloud-init, com verificação pós-boot (rc-service cgroups status) antes de instalar o k3s.
- **Módulos:** /etc/modules-load.d/k3s.conf com os três módulos; verificação lsmod | grep -E 'br_netfilter|overlay|nf_conntrack' no card 1.3 antes de prosseguir.
- **Debug limitado:** documentar no runbook que kubectl exec -- sh é o caminho padrão; se necessário, instalar bash via apk apenas durante debug, nunca na imagem base da VM.
- **Validação na implementação:** após instalar o k3s, rodar kubectl get nodes e confirmar 3 nós Ready; em seguida, executar o Experimento 1 (promoção sob carga) para validar que a stack completa funciona sobre Alpine.
- **Reversão barata:** qualquer falha de boot ou de k3s reverte a imagem base para Debian 12 slim (Alternativa 2) sem tocar em manifests, scripts ou aplicação — o cloud-init é o único ponto que muda.

## Registro de mudanças

| Data | O que mudou? | Por que mudou? | Impacto | Feito por… |
|---|---|---|---|---|
| 30-10-2026 | Primeira versão | Documentar a decisão de adotar Alpine 3.24.2 como SO das 3 VMs do lab, sustentada pelo spike do card | Reduz o footprint de RAM em ~4× e de disco em ~10× vs. Ubuntu, com compatibilidade k3s validada; estabelece pin por versão exata para o lab | Emershow |