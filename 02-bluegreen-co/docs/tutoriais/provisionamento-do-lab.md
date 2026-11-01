# Provisionamento do Laboratório BlueGreen Co.

Este tutorial descreve o passo a passo para provisionar a infraestrutura base do laboratório (VMs Alpine e cluster k3s), refletindo as decisões tomadas durante a Release 1.

## 1. Pré-requisitos
- **Host:** Linux com `libvirt`, `virt-manager` e `qemu-kvm` instalados.
- **Imagens:** ISO do Alpine Linux (ex: `alpine-3.24.2-x86_64.iso`).
- **Hardware:** Mínimo de 16 GB de RAM no host.

## 2. Criação Manual das VMs
> **Nota de Design:** Tentamos usar `virt-install` com `cloud-init` para automatizar isso, mas as imagens cloud do Alpine apresentaram instabilidade com o datasource `nocloud`. Optamos por criar as VMs via interface gráfica e automatizar o resto.

Para cada uma das 3 VMs (`controlplane`, `worker1`, `worker2`):
1. Abra o `virt-manager` e crie uma nova VM.
2. Selecione a ISO do Alpine.
3. Configure: 2 vCPU, 2GB RAM (control plane) ou 3GB RAM (workers), 20GB de disco.
4. Na aba de rede, selecione a rede `default` (ou a rede `lab` se criada).
5. Instale o Alpine usando `setup-alpine`.

## 3. Acesso e Sudo sem Senha (Crucial para Automação)
Para que os scripts rodem sem intervenção manual, copie sua chave SSH para as VMs e configure o `sudo` sem senha:
```
bash
# Substitua pelos IPs reais das suas VMs
for ip in 192.168.122.244 192.168.122.235 192.168.122.100; do
  ssh-copy-id alpine@$ip
  ssh alpine@$ip "echo 'alpine ALL=(ALL) NOPASSWD: ALL' | sudo tee /etc/sudoers.d/alpine > /dev/null && sudo chmod 0440 /etc/sudoers.d/alpine"
done
```

## 4. Preparação do Kernel
O script infra/scripts/prepare-kernel.sh configura o cgroups v2, desativa swap, carrega os módulos do k3s e aplica os sysctls.

```
bash
ssh alpine@IP_DA_VM 'sudo sh -s' < infra/scripts/prepare-kernel.sh
```

## 5. Instalação do k3s
A instalação é orquestrada pelo Makefile (Card 1.6). O alvo lab-up executa o prepare-kernel, instala o control plane (gerando o token), instala os workers e valida o cluster.

Para subir tudo:

```
bash
make lab-up
```

## 6. Validação
Para verificar o status dos nós sem precisar instalar o kubectl no host:

```
bash
make status
Os 3 nós devem aparecer com status Ready.
```