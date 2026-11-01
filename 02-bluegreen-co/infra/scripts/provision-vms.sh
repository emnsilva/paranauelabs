#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LAB_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd)"
source "${SCRIPT_DIR}/lib/common.sh"
[[ -f "${LAB_ROOT}/.env" ]] && source "${LAB_ROOT}/.env"

# --- Configurações ---
LIBVIRT_URI="qemu:///system"
VM_NAMES=("bg-control-plane" "bg-worker-1" "bg-worker-2")
VM_IPS=("192.168.100.10" "192.168.100.11" "192.168.100.12")
VM_MACS=("52:54:00:bb:00:01" "52:54:00:bb:00:02" "52:54:00:bb:00:03")
VM_RAMS=(2048 3072 3072)
VM_VCPUS=2
VM_DISK_SIZE="20G"
BRIDGE_NAME="lab"
LAB_GATEWAY="192.168.100.1"
SSH_USER="lab"

# Fallback para o HOME original caso rode com sudo
REAL_USER="${SUDO_USER:-$USER}"
REAL_HOME=$(getent passwd "$REAL_USER" | cut -d: -f6)
SSH_PUBLIC_KEY="${SSH_PUBLIC_KEY:-${REAL_HOME}/.ssh/id_ed25519.pub}"

# Imagem Alpine
ALPINE_IMAGE_DIR="${ALPINE_IMAGE_DIR:-/media/emerson/HD/labs/isos}"
IMAGE_PATTERN="alpine-3.23.7-x86_64-bios-cloudinit-r0.qcow2"

FORCE=0
[[ "${1:-}" == "--force" ]] && FORCE=1

log "=== Iniciando provisionamento BlueGreen Co. ==="

# 1. Checagens
for cmd in virt-install virsh qemu-img genisoimage; do
  command -v "$cmd" >/dev/null || die "Comando não encontrado: $cmd"
done
[[ -f "${SSH_PUBLIC_KEY}" ]] || die "Chave SSH não encontrada: ${SSH_PUBLIC_KEY}"

BASE_IMG="${ALPINE_IMAGE_DIR}/${IMAGE_PATTERN}"
[[ -f "${BASE_IMG}" ]] || die "Imagem não encontrada: ${BASE_IMG}"

# Valida sha256 se existir
if [[ -f "${BASE_IMG}.sha256" ]]; then
  log "Validando sha256..."
  expected=$(awk '{print $1}' "${BASE_IMG}.sha256")
  actual=$(sha256sum "${BASE_IMG}" | awk '{print $1}')
  [[ "$expected" == "$actual" ]] || die "sha256 divergente! O arquivo pode estar corrompido."
  log "Imagem íntegra."
fi

# 2. Rede libvirt
if ! virsh -c "$LIBVIRT_URI" net-info "$BRIDGE_NAME" >/dev/null 2>&1; then
  log "Criando rede libvirt '$BRIDGE_NAME'..."
  cat > /tmp/net-lab.xml <<EOF
<network>
  <name>${BRIDGE_NAME}</name>
  <forward mode='nat'/>
  <bridge name='virbr-lab' stp='on' delay='0'/>
  <ip address='${LAB_GATEWAY}' netmask='255.255.255.0'>
    <dhcp><range start='192.168.100.100' end='192.168.100.200'/></dhcp>
  </ip>
</network>
EOF
  virsh -c "$LIBVIRT_URI" net-define /tmp/net-lab.xml
  virsh -c "$LIBVIRT_URI" net-start "$BRIDGE_NAME"
  virsh -c "$LIBVIRT_URI" net-autostart "$BRIDGE_NAME"
fi

# 3. Loop de criação das VMs
for i in "${!VM_NAMES[@]}"; do
  vm="${VM_NAMES[$i]}"
  ip="${VM_IPS[$i]}"
  mac="${VM_MACS[$i]}"
  ram="${VM_RAMS[$i]}"
  
  log "--- Preparando $vm ($ip) ---"

  if virsh -c "$LIBVIRT_URI" dominfo "$vm" >/dev/null 2>&1; then
    if [[ $FORCE -eq 1 ]]; then
      log "Removendo VM existente $vm..."
      virsh -c "$LIBVIRT_URI" destroy "$vm" >/dev/null 2>&1 || true
      virsh -c "$LIBVIRT_URI" undefine "$vm" --remove-all-storage --nvram >/dev/null 2>&1 || true
    else
      log "VM $vm já existe. Pulando (use --force para recriar)."
      continue
    fi
  fi

  # Disco overlay
  disk="${ALPINE_IMAGE_DIR}/${vm}.qcow2"
  qemu-img create -f qcow2 -F qcow2 -b "$BASE_IMG" "$disk" "$VM_DISK_SIZE" >/dev/null

  # Cloud-init
  ci_dir="/tmp/ci-${vm}"
  mkdir -p "$ci_dir"
  
  # Substituições seguras (lida com quebra de linha na chave)
  key_content=$(cat "${SSH_PUBLIC_KEY}" | tr -d '\n')
  
  sed -e "s|__HOSTNAME__|${vm}|g" \
      -e "s|__SSH_USER__|${SSH_USER}|g" \
      -e "s|__SSH_PUBLIC_KEY__|${key_content}|g" \
      "${LAB_ROOT}/infra/cloud-init/user-data.tpl" > "$ci_dir/user-data"
      
  sed -e "s|__HOSTNAME__|${vm}|g" \
      "${LAB_ROOT}/infra/cloud-init/meta-data.tpl" > "$ci_dir/meta-data"
      
  sed -e "s|__IP__|${ip}|g" \
      -e "s|__MAC__|${mac}|g" \
      -e "s|__GATEWAY__|${LAB_GATEWAY}|g" \
      "${LAB_ROOT}/infra/cloud-init/network-config.tpl" > "$ci_dir/network-config"

  genisoimage -quiet -output "$ci_dir/seed.iso" -volid cidata -joliet -rock \
    "$ci_dir/user-data" "$ci_dir/meta-data" "$ci_dir/network-config"

  # Cria a VM
  log "Criando VM $vm..."
  virt-install \
    --connect "$LIBVIRT_URI" \
    --name "$vm" \
    --memory "$ram" \
    --vcpus "$VM_VCPUS" \
    --cpu host-passthrough \
    --disk "path=${disk},format=qcow2,bus=virtio" \
    --disk "path=${ci_dir}/seed.iso,device=disk,bus=virtio,readonly=on" \
    --network "bridge=virbr-lab,model=virtio,mac=${mac}" \
    --import \
    --osinfo detect=on,require=off \
    --graphics none \
    --noautoconsole >/dev/null
done

# 4. Aguarda SSH
log "Aguardando as VMs subirem..."
for i in "${!VM_NAMES[@]}"; do
  vm="${VM_NAMES[$i]}"
  ip="${VM_IPS[$i]}"
  log "Aguardando SSH em $vm ($ip)..."
  for ((t=0; t<60; t++)); do
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=3 -o BatchMode=yes "$SSH_USER@$ip" "true" 2>/dev/null; then
      log "$vm pronta."
      break
    fi
    sleep 5
    [[ $t -eq 59 ]] && die "Timeout aguardando SSH em $vm. Verifique com 'virsh console $vm'."
  done
done

# 5. Inventário
mkdir -p "${LAB_ROOT}/infra/inventory"
cat > "${LAB_ROOT}/infra/inventory/hosts.yml" <<EOF
# Gerado automaticamente
all:
  vars:
    ansible_user: ${SSH_USER}
  children:
    control_plane:
      hosts:
        ${VM_NAMES[0]}:
          ansible_host: ${VM_IPS[0]}
    workers:
      hosts:
        ${VM_NAMES[1]}:
          ansible_host: ${VM_IPS[1]}
        ${VM_NAMES[2]}:
          ansible_host: ${VM_IPS[2]}
EOF

log "=== Provisionamento concluído com sucesso! ==="