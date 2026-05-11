#!/usr/bin/env bash
set -euo pipefail

PROJECT_NAME="OSTRA"
PROJECT_EXPANDED="One Script To Run 'em All"
CONFIG_DIR="${HOME}/.config/ostra"
CONFIG_FILE="${CONFIG_DIR}/config.env"
STATE_FILE="${CONFIG_DIR}/state.env"
VM_NAME_PREFIX="ostra-k3s"

usage() {
  cat <<EOF
$PROJECT_NAME - $PROJECT_EXPANDED

Usage:
  ostra.sh

Notes:
  - This script always runs the default interactive flow.
  - Prompts read from /dev/tty, so curl|bash stays interactive.
  - Config is stored in $CONFIG_FILE
  - Generated state is stored in $STATE_FILE
EOF
}

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
RESET='\033[0m'

log() {
  echo -e "${BLUE}[$PROJECT_NAME]${RESET} $*"
}

die() {
  echo -e "${RED}[$PROJECT_NAME] ERROR:${RESET} $*" >&2
  exit 1
}

ensure_dirs() {
  mkdir -p "$CONFIG_DIR"
}

has_tty() {
  [[ -r /dev/tty ]] && (: </dev/tty) >/dev/null 2>&1
}

load_env_file() {
  local file="$1"
  if [[ -f "$file" ]]; then
    # shellcheck disable=SC1090
    source "$file"
  fi
}

save_default_config_if_missing() {
  if [[ ! -f "$CONFIG_FILE" ]]; then
    cat > "$CONFIG_FILE" <<EOF
# OSTRA user config
PROXMOX_SSH_USER=root
PROXMOX_NODE_1_NAME=node1
PROXMOX_NODE_1_IP=
PROXMOX_NODE_2_NAME=node2
PROXMOX_NODE_2_IP=
PROXMOX_NODE_3_NAME=node3
PROXMOX_NODE_3_IP=
BRIDGE=vmbr0
GATEWAY=
CIDR=24
VM_OS=debian-12
VM_DISK_GB=64
K3S_VERSION=v1.32.4+k3s1
LONGHORN_VERSION=v1.9.1
LONGHORN_UI_NODEPORT=30080
METALLB_VERSION=v0.14.9
METALLB_IP_RANGE_START=
METALLB_IP_RANGE_END=
ARGO_ENABLED=
ARGO_VERSION=v2.14.11
ARGO_UI_NODEPORT=30081
ARGO_GITHUB_REPO=
ARGO_GITHUB_BRANCH=main
ARGO_APP_PATH=.
ARGO_APP_NAMESPACE=default
ARGO_APP_NAME=homelab
VM_NODE_1_VCPUS=4
VM_NODE_1_RAM_MB=8192
VM_NODE_2_VCPUS=2
VM_NODE_2_RAM_MB=6144
VM_NODE_3_VCPUS=2
VM_NODE_3_RAM_MB=4096
PROXMOX_NODE_1_STORAGE=
PROXMOX_NODE_2_STORAGE=
PROXMOX_NODE_3_STORAGE=
STORAGE_ONLY_NODE_INDEX=
EOF
  fi
}

save_default_state_if_missing() {
  if [[ ! -f "$STATE_FILE" ]]; then
    cat > "$STATE_FILE" <<EOF
# OSTRA generated state
TEMPLATE_VMID_NODE_1=
TEMPLATE_VMID_NODE_2=
TEMPLATE_VMID_NODE_3=
VMID_NODE_1=
VMID_NODE_2=
VMID_NODE_3=
VM_IP_NODE_1=
VM_IP_NODE_2=
VM_IP_NODE_3=
VM_NAME_NODE_1=
VM_NAME_NODE_2=
VM_NAME_NODE_3=
K3S_TOKEN=
EOF
  fi
}

write_config() {
  cat > "$CONFIG_FILE" <<EOF
# OSTRA user config
PROXMOX_SSH_USER=${PROXMOX_SSH_USER:-root}
PROXMOX_NODE_1_NAME=${PROXMOX_NODE_1_NAME:-node1}
PROXMOX_NODE_1_IP=${PROXMOX_NODE_1_IP:-}
PROXMOX_NODE_2_NAME=${PROXMOX_NODE_2_NAME:-node2}
PROXMOX_NODE_2_IP=${PROXMOX_NODE_2_IP:-}
PROXMOX_NODE_3_NAME=${PROXMOX_NODE_3_NAME:-node3}
PROXMOX_NODE_3_IP=${PROXMOX_NODE_3_IP:-}
BRIDGE=${BRIDGE:-vmbr0}
GATEWAY=${GATEWAY:-}
CIDR=${CIDR:-24}
VM_OS=${VM_OS:-debian-12}
VM_DISK_GB=${VM_DISK_GB:-64}
K3S_VERSION=${K3S_VERSION:-v1.32.4+k3s1}
LONGHORN_VERSION=${LONGHORN_VERSION:-v1.9.1}
LONGHORN_UI_NODEPORT=${LONGHORN_UI_NODEPORT:-30080}
METALLB_VERSION=${METALLB_VERSION:-v0.14.9}
METALLB_IP_RANGE_START=${METALLB_IP_RANGE_START:-}
METALLB_IP_RANGE_END=${METALLB_IP_RANGE_END:-}
ARGO_ENABLED=${ARGO_ENABLED:-}
ARGO_VERSION=${ARGO_VERSION:-v2.14.11}
ARGO_UI_NODEPORT=${ARGO_UI_NODEPORT:-30081}
ARGO_GITHUB_REPO=${ARGO_GITHUB_REPO:-}
ARGO_GITHUB_BRANCH=${ARGO_GITHUB_BRANCH:-main}
ARGO_APP_PATH=${ARGO_APP_PATH:-.}
ARGO_APP_NAMESPACE=${ARGO_APP_NAMESPACE:-default}
ARGO_APP_NAME=${ARGO_APP_NAME:-homelab}
VM_NODE_1_VCPUS=${VM_NODE_1_VCPUS:-4}
VM_NODE_1_RAM_MB=${VM_NODE_1_RAM_MB:-8192}
VM_NODE_2_VCPUS=${VM_NODE_2_VCPUS:-2}
VM_NODE_2_RAM_MB=${VM_NODE_2_RAM_MB:-6144}
VM_NODE_3_VCPUS=${VM_NODE_3_VCPUS:-2}
VM_NODE_3_RAM_MB=${VM_NODE_3_RAM_MB:-4096}
PROXMOX_NODE_1_STORAGE=${PROXMOX_NODE_1_STORAGE:-}
PROXMOX_NODE_2_STORAGE=${PROXMOX_NODE_2_STORAGE:-}
PROXMOX_NODE_3_STORAGE=${PROXMOX_NODE_3_STORAGE:-}
STORAGE_ONLY_NODE_INDEX=${STORAGE_ONLY_NODE_INDEX:-}
EOF
}

write_state() {
  cat > "$STATE_FILE" <<EOF
# OSTRA generated state
TEMPLATE_VMID_NODE_1=${TEMPLATE_VMID_NODE_1:-}
TEMPLATE_VMID_NODE_2=${TEMPLATE_VMID_NODE_2:-}
TEMPLATE_VMID_NODE_3=${TEMPLATE_VMID_NODE_3:-}
VMID_NODE_1=${VMID_NODE_1:-}
VMID_NODE_2=${VMID_NODE_2:-}
VMID_NODE_3=${VMID_NODE_3:-}
VM_IP_NODE_1=${VM_IP_NODE_1:-}
VM_IP_NODE_2=${VM_IP_NODE_2:-}
VM_IP_NODE_3=${VM_IP_NODE_3:-}
VM_NAME_NODE_1=${VM_NAME_NODE_1:-}
VM_NAME_NODE_2=${VM_NAME_NODE_2:-}
VM_NAME_NODE_3=${VM_NAME_NODE_3:-}
K3S_TOKEN=${K3S_TOKEN:-}
EOF
}

ssh_node() {
  local ip="$1"
  shift
  ssh -o BatchMode=yes -o ConnectTimeout=5 -o StrictHostKeyChecking=accept-new "${PROXMOX_SSH_USER}@${ip}" "$@"
}

guest_ssh() {
  local ip="$1"
  shift
  ssh \
    -o BatchMode=yes \
    -o ConnectTimeout=5 \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    "$(vm_guest_user)@${ip}" "$@"
}

host_reachable() {
  local ip="$1"
  ssh_node "$ip" "true" >/dev/null 2>&1
}

ensure_proxmox_connectivity() {
  local idx ip_var ip_value
  for idx in 1 2 3; do
    ip_var="PROXMOX_NODE_${idx}_IP"
    ip_value="${!ip_var}"
    if host_reachable "$ip_value"; then
      log "Proxmox node ${idx} reachable at ${ip_value}"
    else
      die "Cannot SSH to Proxmox node ${idx} at ${ip_value} as ${PROXMOX_SSH_USER}"
    fi
  done
}

all_proxmox_vmids() {
  local idx ip_var ip_value
  for idx in 1 2 3; do
    ip_var="PROXMOX_NODE_${idx}_IP"
    ip_value="${!ip_var}"
    ssh_node "$ip_value" "qm list | awk 'NR>1 {print \$1}'" 2>/dev/null || true
  done | awk 'NF' | sort -n | uniq
}

vmid_is_used() {
  local vmid="$1"
  all_proxmox_vmids | grep -qx "$vmid"
}

next_free_vmid() {
  local candidate="${1:-200}"
  while vmid_is_used "$candidate"; do
    candidate=$((candidate + 1))
  done
  echo "$candidate"
}

ip_responds() {
  local ip="$1"
  ping -c 1 -W 1 "$ip" >/dev/null 2>&1
}

ip_ssh_responds() {
  local ip="$1"
  ssh -o BatchMode=yes -o ConnectTimeout=2 -o StrictHostKeyChecking=accept-new "$PROXMOX_SSH_USER@$ip" "true" >/dev/null 2>&1
}

find_free_ip_block() {
  local base prefix start host ip ok
  prefix="$(same_subnet_prefix_3 "$PROXMOX_NODE_1_IP")"

  for start in $(seq 210 247); do
    ok=1
    for host in "$start" $((start + 1)) $((start + 2)); do
      ip="${prefix}.${host}"
      if ip_responds "$ip" || ip_ssh_responds "$ip"; then
        ok=0
        break
      fi
    done
    if (( ok == 1 )); then
      echo "${prefix}.${start}"
      return 0
    fi
  done

  return 1
}

assign_state_defaults() {
  if [[ -z "${VM_NAME_NODE_1:-}" ]]; then
    VM_NAME_NODE_1="${VM_NAME_PREFIX}-1"
  fi
  if [[ -z "${VM_NAME_NODE_2:-}" ]]; then
    VM_NAME_NODE_2="${VM_NAME_PREFIX}-2"
  fi
  if [[ -z "${VM_NAME_NODE_3:-}" ]]; then
    VM_NAME_NODE_3="${VM_NAME_PREFIX}-3"
  fi

  if [[ -z "${TEMPLATE_VMID_NODE_1:-}" ]]; then
    TEMPLATE_VMID_NODE_1="$(next_free_vmid 9000)"
  fi
  if [[ -z "${TEMPLATE_VMID_NODE_2:-}" ]]; then
    TEMPLATE_VMID_NODE_2="$(next_free_vmid $((TEMPLATE_VMID_NODE_1 + 1)))"
  fi
  if [[ -z "${TEMPLATE_VMID_NODE_3:-}" ]]; then
    TEMPLATE_VMID_NODE_3="$(next_free_vmid $((TEMPLATE_VMID_NODE_2 + 1)))"
  fi

  if [[ -z "${VMID_NODE_1:-}" ]]; then
    VMID_NODE_1="$(next_free_vmid 210)"
  fi
  if [[ -z "${VMID_NODE_2:-}" ]]; then
    VMID_NODE_2="$(next_free_vmid $((VMID_NODE_1 + 1)))"
  fi
  if [[ -z "${VMID_NODE_3:-}" ]]; then
    VMID_NODE_3="$(next_free_vmid $((VMID_NODE_2 + 1)))"
  fi

  if [[ -z "${VM_IP_NODE_1:-}" || -z "${VM_IP_NODE_2:-}" || -z "${VM_IP_NODE_3:-}" ]]; then
    local first_ip a b c d
    first_ip="$(find_free_ip_block)" || die "Could not find a free 3-IP block in the subnet"
    IFS=. read -r a b c d <<< "$first_ip"
    VM_IP_NODE_1="${a}.${b}.${c}.${d}"
    VM_IP_NODE_2="${a}.${b}.${c}.$((d + 1))"
    VM_IP_NODE_3="${a}.${b}.${c}.$((d + 2))"
  fi

  write_state
}

auto_vm_storage_target() {
  local proxmox_ip="$1"
  ssh_node "$proxmox_ip" "pvesm status -content images | awk 'NR>1 && \$3 == \"active\" {print \$1}'" | awk '
    $1 == "singlepool" { print; found=1; exit }
    $1 == "local-lvm" { fallback=$1 }
    END { if (!found && fallback) print fallback }
  '
}

configured_vm_storage_target() {
  local idx="$1"
  local proxmox_ip_var="PROXMOX_NODE_${idx}_IP"
  local storage_var="PROXMOX_NODE_${idx}_STORAGE"
  local proxmox_ip="${!proxmox_ip_var}"
  local configured="${!storage_var:-}"

  if [[ -n "$configured" ]]; then
    echo "$configured"
  else
    auto_vm_storage_target "$proxmox_ip"
  fi
}

template_exists_on_node() {
  local proxmox_ip="$1"
  local vmid="$2"
  ssh_node "$proxmox_ip" "qm config ${vmid} 2>/dev/null | grep -q '^template: 1$'"
}

template_disk_storage_on_node() {
  local proxmox_ip="$1"
  local vmid="$2"
  ssh_node "$proxmox_ip" "qm config ${vmid} 2>/dev/null | awk -F '[:,]' '/^scsi0:/ {gsub(/^ +| +$/, \"\", \$2); print \$2; exit}'"
}

ensure_template_image_file() {
  local proxmox_ip="$1"
  local image_path="${2}"
  ssh_node "$proxmox_ip" "mkdir -p \$(dirname '${image_path}') && test -f '${image_path}' || wget -qO '${image_path}' https://cloud.debian.org/images/cloud/bookworm/latest/debian-12-genericcloud-amd64.qcow2"
}

ensure_template_on_node() {
  local idx="$1"
  local proxmox_ip_var="PROXMOX_NODE_${idx}_IP"
  local proxmox_name_var="PROXMOX_NODE_${idx}_NAME"
  local template_vmid_var="TEMPLATE_VMID_NODE_${idx}"
  local proxmox_ip="${!proxmox_ip_var}"
  local proxmox_name="${!proxmox_name_var}"
  local template_vmid="${!template_vmid_var}"
  local storage image_path

  storage="$(configured_vm_storage_target "$idx")"
  [[ -n "$storage" ]] || die "Could not find image-capable storage on ${proxmox_name}"

  if template_exists_on_node "$proxmox_ip" "$template_vmid"; then
    local current_storage
    current_storage="$(template_disk_storage_on_node "$proxmox_ip" "$template_vmid")"
    if [[ "$current_storage" == "$storage" ]]; then
      log "Template VMID ${template_vmid} already exists on ${proxmox_name}"
      return 0
    fi

    log "Moving template ${template_vmid} on ${proxmox_name} from ${current_storage} to ${storage}"
    ssh_node "$proxmox_ip" "qm move_disk ${template_vmid} scsi0 ${storage} --delete 1"
    return 0
  fi

  image_path="/var/lib/vz/template/qcow2/debian-12-genericcloud-amd64.qcow2"

  log "Creating Debian cloud-init template ${template_vmid} on ${proxmox_name} using storage ${storage}"
  ensure_template_image_file "$proxmox_ip" "$image_path"
  ssh_node "$proxmox_ip" "qm destroy ${template_vmid} --purge >/dev/null 2>&1 || true"
  ssh_node "$proxmox_ip" "qm create ${template_vmid} --name ostra-debian12-template --memory 2048 --cores 2 --net0 virtio,bridge=${BRIDGE}"
  ssh_node "$proxmox_ip" "qm importdisk ${template_vmid} ${image_path} ${storage}"
  ssh_node "$proxmox_ip" "qm set ${template_vmid} --scsihw virtio-scsi-pci --scsi0 ${storage}:vm-${template_vmid}-disk-0"
  ssh_node "$proxmox_ip" "qm set ${template_vmid} --ide2 ${storage}:cloudinit"
  ssh_node "$proxmox_ip" "qm set ${template_vmid} --boot order=scsi0 --bootdisk scsi0 --vga std --agent enabled=1 --ostype l26"
  ssh_node "$proxmox_ip" "qm template ${template_vmid}"
}

ensure_all_templates() {
  ensure_template_on_node 1
  ensure_template_on_node 2
  ensure_template_on_node 3
}

vm_exists_on_node() {
  local proxmox_ip="$1"
  local vmid="$2"
  ssh_node "$proxmox_ip" "qm status ${vmid} >/dev/null 2>&1"
}

qm_config_value() {
  local proxmox_ip="$1"
  local vmid="$2"
  local key="$3"
  ssh_node "$proxmox_ip" "qm config ${vmid} 2>/dev/null | awk -F': ' '/^${key}:/ {print \$2; exit}'"
}

vm_needs_reconfig() {
  local idx="$1"
  local proxmox_ip_var="PROXMOX_NODE_${idx}_IP"
  local vmid_var="VMID_NODE_${idx}"
  local guest_ip_var="VM_IP_NODE_${idx}"
  local vcpus_var="VM_NODE_${idx}_VCPUS"
  local ram_var="VM_NODE_${idx}_RAM_MB"
  local proxmox_ip="${!proxmox_ip_var}"
  local vmid="${!vmid_var}"
  local guest_ip="${!guest_ip_var}"
  local vcpus="${!vcpus_var}"
  local ram_mb="${!ram_var}"
  local current_cores current_memory current_ciuser current_ipconfig0 current_net0 current_agent current_vga

  current_cores="$(qm_config_value "$proxmox_ip" "$vmid" cores)"
  current_memory="$(qm_config_value "$proxmox_ip" "$vmid" memory)"
  current_ciuser="$(qm_config_value "$proxmox_ip" "$vmid" ciuser)"
  current_ipconfig0="$(qm_config_value "$proxmox_ip" "$vmid" ipconfig0)"
  current_net0="$(qm_config_value "$proxmox_ip" "$vmid" net0)"
  current_agent="$(qm_config_value "$proxmox_ip" "$vmid" agent)"
  current_vga="$(qm_config_value "$proxmox_ip" "$vmid" vga)"

  [[ "$current_cores" == "$vcpus" ]] || return 0
  [[ "$current_memory" == "$ram_mb" ]] || return 0
  [[ "$current_ciuser" == "$(vm_guest_user)" ]] || return 0
  [[ "$current_ipconfig0" == "ip=${guest_ip}/${CIDR},gw=${GATEWAY}" ]] || return 0
  [[ "$current_net0" == *"bridge=${BRIDGE}"* ]] || return 0
  [[ "$current_agent" == "enabled=1" ]] || return 0
  [[ "$current_vga" == "std" ]] || return 0
  return 1
}

summarize_vm_targets() {
  cat <<EOF
Planned OSTRA VMs:
- ${VM_NAME_NODE_1:-unset} on ${PROXMOX_NODE_1_NAME} (${PROXMOX_NODE_1_IP}) -> VMID ${VMID_NODE_1:-unset}, guest IP ${VM_IP_NODE_1:-unset}
- ${VM_NAME_NODE_2:-unset} on ${PROXMOX_NODE_2_NAME} (${PROXMOX_NODE_2_IP}) -> VMID ${VMID_NODE_2:-unset}, guest IP ${VM_IP_NODE_2:-unset}
- ${VM_NAME_NODE_3:-unset} on ${PROXMOX_NODE_3_NAME} (${PROXMOX_NODE_3_IP}) -> VMID ${VMID_NODE_3:-unset}, guest IP ${VM_IP_NODE_3:-unset}
EOF
}

report_vm_presence() {
  local idx proxmox_ip_var vmid_var name_var proxmox_name_var proxmox_ip vmid name proxmox_name
  echo "Existing VM presence:"
  for idx in 1 2 3; do
    proxmox_ip_var="PROXMOX_NODE_${idx}_IP"
    proxmox_name_var="PROXMOX_NODE_${idx}_NAME"
    vmid_var="VMID_NODE_${idx}"
    name_var="VM_NAME_NODE_${idx}"
    proxmox_ip="${!proxmox_ip_var}"
    proxmox_name="${!proxmox_name_var}"
    vmid="${!vmid_var:-}"
    name="${!name_var:-}"
    if vm_exists_on_node "$proxmox_ip" "$vmid"; then
      echo "- ${name} already exists on ${proxmox_name} as VMID ${vmid}"
    else
      echo "- ${name} missing on ${proxmox_name} (planned VMID ${vmid})"
    fi
  done
}

ensure_ssh_public_key() {
  if [[ -n "${OSTRA_SSH_PUBLIC_KEY:-}" ]]; then
    return 0
  fi

  if [[ -f "${HOME}/.ssh/id_ed25519.pub" ]]; then
    OSTRA_SSH_PUBLIC_KEY="$(<"${HOME}/.ssh/id_ed25519.pub")"
  elif [[ -f "${HOME}/.ssh/id_rsa.pub" ]]; then
    OSTRA_SSH_PUBLIC_KEY="$(<"${HOME}/.ssh/id_rsa.pub")"
  else
    die "No SSH public key found in ~/.ssh (expected id_ed25519.pub or id_rsa.pub)"
  fi
}

install_ssh_key_snippet_on_node() {
  local proxmox_ip="$1"
  local remote_key_file="/tmp/ostra-authorized-key.pub"
  ssh_node "$proxmox_ip" "cat > ${remote_key_file}" <<EOF
${OSTRA_SSH_PUBLIC_KEY}
EOF
  echo "$remote_key_file"
}

vm_guest_user() {
  echo "debian"
}

guest_reachable() {
  local ip="$1"
  guest_ssh "$ip" "true" >/dev/null 2>&1
}

wait_for_guest_ssh() {
  local name="$1"
  local ip="$2"
  local attempts="${3:-60}"
  local i
  for i in $(seq 1 "$attempts"); do
    if guest_reachable "$ip"; then
      log "Guest ${name} reachable via SSH at ${ip}"
      return 0
    fi
    sleep 5
  done
  return 1
}

clear_cloud_init_state_on_node() {
  local proxmox_ip="$1"
  local vmid="$2"
  local disk_path="$3"
  local map_name="$4"
  local sectors="133955551"
  ssh_node "$proxmox_ip" "qm stop ${vmid} >/dev/null 2>&1 || true; echo '0 ${sectors} linear ${disk_path} 262144' | dmsetup create ${map_name}; mkdir -p /mnt/${map_name}; mount /dev/mapper/${map_name} /mnt/${map_name}; rm -rf /mnt/${map_name}/var/lib/cloud/*; mkdir -p /mnt/${map_name}/var/lib/cloud; sync; umount /mnt/${map_name}; dmsetup remove ${map_name}; qm start ${vmid} >/dev/null 2>&1 || true"
}

recover_guest_cloud_init() {
  local idx="$1"
  local proxmox_ip_var="PROXMOX_NODE_${idx}_IP"
  local proxmox_name_var="PROXMOX_NODE_${idx}_NAME"
  local vmid_var="VMID_NODE_${idx}"
  local storage_var="PROXMOX_NODE_${idx}_STORAGE"
  local proxmox_ip="${!proxmox_ip_var}"
  local proxmox_name="${!proxmox_name_var}"
  local vmid="${!vmid_var}"
  local storage="${!storage_var:-}"
  local name_var="VM_NAME_NODE_${idx}"
  local name="${!name_var}"
  local disk_path map_name

  if [[ -z "$storage" ]]; then
    storage="$(configured_vm_storage_target "$idx")"
  fi

  if [[ "$storage" == "singlepool" ]]; then
    disk_path="/dev/zvol/singlepool/vm-${vmid}-disk-0"
  else
    disk_path="/dev/pve/vm-${vmid}-disk-0"
  fi
  map_name="ostra${vmid}p1"

  log "Attempting cloud-init state recovery for ${name} on ${proxmox_name}"
  clear_cloud_init_state_on_node "$proxmox_ip" "$vmid" "$disk_path" "$map_name"
}

ensure_guest_ssh_with_recovery() {
  local idx="$1"
  local name_var="VM_NAME_NODE_${idx}"
  local ip_var="VM_IP_NODE_${idx}"
  local name="${!name_var}"
  local ip="${!ip_var}"

  if wait_for_guest_ssh "$name" "$ip" 12; then
    return 0
  fi

  recover_guest_cloud_init "$idx"
  wait_for_guest_ssh "$name" "$ip" 24 || die "Guest $name not reachable after recovery"
}

ensure_all_guest_ssh() {
  ensure_guest_ssh_with_recovery 1
  ensure_guest_ssh_with_recovery 2
  ensure_guest_ssh_with_recovery 3
}

random_token() {
  if command -v openssl >/dev/null 2>&1; then
    openssl rand -hex 24
  else
    date +%s | sha256sum | cut -d' ' -f1 | cut -c1-48
  fi
}

ensure_k3s_token() {
  if [[ -z "${K3S_TOKEN:-}" ]]; then
    K3S_TOKEN="$(random_token)"
    write_state
  fi
}

k3s_server_ready() {
  guest_ssh "$VM_IP_NODE_1" "sudo test -f /etc/rancher/k3s/k3s.yaml && sudo kubectl get nodes >/dev/null 2>&1"
}

ensure_k3s_server() {
  ensure_k3s_token
  if k3s_server_ready; then
    log "K3s server already installed on ${VM_NAME_NODE_1}"
    return 0
  fi

  log "Installing K3s server on ${VM_NAME_NODE_1}"
  guest_ssh "$VM_IP_NODE_1" "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${K3S_VERSION}' K3S_TOKEN='${K3S_TOKEN}' sh -s - --write-kubeconfig-mode 644"
}

k3s_agent_joined() {
  local ip="$1"
  guest_ssh "$ip" "sudo systemctl is-active k3s-agent >/dev/null 2>&1"
}

ensure_k3s_agent() {
  local idx="$1"
  local name_var="VM_NAME_NODE_${idx}"
  local ip_var="VM_IP_NODE_${idx}"
  local name="${!name_var}"
  local ip="${!ip_var}"

  if k3s_agent_joined "$ip"; then
    log "K3s agent already installed on ${name}"
    return 0
  fi

  log "Installing K3s agent on ${name}"
  guest_ssh "$ip" "curl -sfL https://get.k3s.io | INSTALL_K3S_VERSION='${K3S_VERSION}' K3S_URL='https://${VM_IP_NODE_1}:6443' K3S_TOKEN='${K3S_TOKEN}' sh -"
}

ensure_storage_only_taint() {
  if [[ -z "${STORAGE_ONLY_NODE_INDEX:-}" ]]; then
    return 0
  fi

  local name_var="VM_NAME_NODE_${STORAGE_ONLY_NODE_INDEX}"
  local node_name="${!name_var}"
  log "Applying storage-only taint to ${node_name}"
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl taint node ${node_name} ostra/storage-only=true:NoSchedule --overwrite"
}

ensure_k3s_cluster() {
  ensure_k3s_server
  ensure_k3s_agent 2
  ensure_k3s_agent 3
  ensure_storage_only_taint
}

ensure_longhorn_prereqs_on_guest() {
  local ip="$1"
  guest_ssh "$ip" "sudo apt-get update -qq && sudo DEBIAN_FRONTEND=noninteractive apt-get install -y -qq open-iscsi nfs-common >/dev/null && sudo systemctl enable --now iscsid >/dev/null"
}

ensure_longhorn_prereqs() {
  log "Installing Longhorn prerequisites on guests"
  ensure_longhorn_prereqs_on_guest "$VM_IP_NODE_1"
  ensure_longhorn_prereqs_on_guest "$VM_IP_NODE_2"
  ensure_longhorn_prereqs_on_guest "$VM_IP_NODE_3"
}

longhorn_installed() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl get ns longhorn-system >/dev/null 2>&1"
}

patch_longhorn_tolerations() {
  local tol='[{"key":"ostra/storage-only","operator":"Equal","value":"true","effect":"NoSchedule"}]'
  guest_ssh "$VM_IP_NODE_1" "for kind in daemonset deployment; do for name in \$(sudo kubectl -n longhorn-system get \$kind -o name 2>/dev/null); do sudo kubectl -n longhorn-system patch \$name --type merge -p '{\"spec\":{\"template\":{\"spec\":{\"tolerations\":${tol}}}}}' >/dev/null || true; done; done"
}

wait_for_longhorn() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl -n longhorn-system rollout status deploy/longhorn-driver-deployer --timeout=300s >/dev/null && sudo kubectl -n longhorn-system rollout status deploy/longhorn-ui --timeout=300s >/dev/null"
}

metallb_installed() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl get ns metallb-system >/dev/null 2>&1"
}

wait_for_metallb() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl -n metallb-system rollout status deploy/controller --timeout=300s >/dev/null && sudo kubectl -n metallb-system rollout status ds/speaker --timeout=300s >/dev/null"
}

ensure_traefik_loadbalancer() {
  log "Exposing Traefik ingress controller on LoadBalancer IP"
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl patch svc traefik -n kube-system --type merge -p '{\"spec\":{\"type\":\"LoadBalancer\"}}' >/dev/null 2>&1 || true"
  # Wait for Traefik to get an external IP
  local attempts=0
  while [[ $attempts -lt 30 ]]; do
    local ip
    ip="$(guest_ssh "$VM_IP_NODE_1" "sudo kubectl -n kube-system get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null" 2>/dev/null || true)"
    if [[ -n "$ip" ]]; then
      log "Traefik ingress available at: http://${ip}"
      return 0
    fi
    sleep 2
    attempts=$((attempts + 1))
  done
  log "Warning: Traefik IP not assigned yet (MetalLB may still be configuring)"
}

get_traefik_ip() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl -n kube-system get svc traefik -o jsonpath='{.status.loadBalancer.ingress[0].ip}' 2>/dev/null" 2>/dev/null || echo ""
}

ensure_metallb() {
  if metallb_installed; then
    log "MetalLB already installed"
    return 0
  fi

  [[ -n "${METALLB_IP_RANGE_START:-}" ]] || die "METALLB_IP_RANGE_START not configured"
  [[ -n "${METALLB_IP_RANGE_END:-}" ]] || die "METALLB_IP_RANGE_END not configured"

  log "Installing MetalLB ${METALLB_VERSION}"
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl apply -f https://raw.githubusercontent.com/metallb/metallb/${METALLB_VERSION}/config/manifests/metallb-native.yaml >/dev/null"
  wait_for_metallb

  log "Configuring MetalLB IP pool"
  guest_ssh "$VM_IP_NODE_1" "cat <<'EOF' | sudo kubectl apply -f - >/dev/null
apiVersion: metallb.io/v1beta1
kind: IPAddressPool
metadata:
  name: ostra-pool
  namespace: metallb-system
spec:
  addresses:
  - ${METALLB_IP_RANGE_START}-${METALLB_IP_RANGE_END}
---
apiVersion: metallb.io/v1beta1
kind: L2Advertisement
metadata:
  name: ostra-l2
  namespace: metallb-system
EOF"
}

ensure_longhorn_dashboard() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl -n longhorn-system patch svc longhorn-frontend --type merge -p '{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"port\":80,\"targetPort\":8000,\"nodePort\":${LONGHORN_UI_NODEPORT},\"protocol\":\"TCP\"}]}}' >/dev/null"
}

ensure_longhorn() {
  ensure_longhorn_prereqs
  if longhorn_installed; then
    log "Longhorn already installed"
    patch_longhorn_tolerations
    ensure_longhorn_dashboard
    return 0
  fi

  log "Installing Longhorn ${LONGHORN_VERSION}"
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl apply -f https://raw.githubusercontent.com/longhorn/longhorn/${LONGHORN_VERSION}/deploy/longhorn.yaml >/dev/null"
  patch_longhorn_tolerations
  wait_for_longhorn
  ensure_longhorn_dashboard
}

normalize_github_repo_url() {
  local repo="$1"
  repo="${repo#https://github.com/}"
  repo="${repo#http://github.com/}"
  repo="${repo#git@github.com:}"
  repo="${repo%.git}"
  echo "$repo"
}

argo_enabled() {
  [[ "${ARGO_ENABLED:-}" == "1" || "${ARGO_ENABLED:-}" == "true" || "${ARGO_ENABLED:-}" == "yes" ]]
}

argocd_installed() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl get ns argocd >/dev/null 2>&1"
}

wait_for_argocd() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl -n argocd rollout status deploy/argocd-server --timeout=300s >/dev/null && sudo kubectl -n argocd rollout status deploy/argocd-repo-server --timeout=300s >/dev/null && sudo kubectl -n argocd rollout status statefulset/argocd-application-controller --timeout=300s >/dev/null"
}

ensure_argocd_dashboard() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl -n argocd patch svc argocd-server --type merge -p '{\"spec\":{\"type\":\"NodePort\",\"ports\":[{\"name\":\"http\",\"port\":80,\"protocol\":\"TCP\",\"targetPort\":8080,\"nodePort\":${ARGO_UI_NODEPORT}}]}}' >/dev/null"
}

ensure_argocd() {
  if argocd_installed; then
    log "Argo CD already installed"
    ensure_argocd_dashboard
    return 0
  fi

  log "Installing Argo CD ${ARGO_VERSION}"
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl create namespace argocd >/dev/null 2>&1 || true && sudo kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/${ARGO_VERSION}/manifests/install.yaml >/dev/null"
  wait_for_argocd
  log "Configuring Argo CD for HTTP (insecure mode)"
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl patch configmap argocd-cmd-params-cm -n argocd --type merge -p '{\"data\":{\"server.insecure\":\"true\"}}' >/dev/null && sudo kubectl rollout restart deployment argocd-server -n argocd >/dev/null"
  sleep 5
  wait_for_argocd
  ensure_argocd_dashboard
}

ensure_gh_auth() {
  command -v gh >/dev/null 2>&1 || die "gh CLI is required. Install it and run gh auth login"
  gh auth status >/dev/null 2>&1 || die "GitHub auth missing. Run: gh auth login"
}

gh_token_for_argocd() {
  gh auth token
}

ensure_argocd_repo_secret() {
  local repo="$1"
  local token="$2"
  local repo_url="https://github.com/${repo}.git"
  guest_ssh "$VM_IP_NODE_1" "cat <<'EOF' | sudo kubectl apply -f - >/dev/null
apiVersion: v1
kind: Secret
metadata:
  name: ostra-argocd-repo
  namespace: argocd
  labels:
    argocd.argoproj.io/secret-type: repository
stringData:
  type: git
  url: ${repo_url}
  username: x-access-token
  password: ${token}
EOF"
}

ensure_argocd_application() {
  local repo="$1"
  local repo_url="https://github.com/${repo}.git"
  guest_ssh "$VM_IP_NODE_1" "cat <<'EOF' | sudo kubectl apply -f - >/dev/null
apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: ${ARGO_APP_NAME}
  namespace: argocd
spec:
  project: default
  source:
    repoURL: ${repo_url}
    targetRevision: ${ARGO_GITHUB_BRANCH}
    path: ${ARGO_APP_PATH}
  destination:
    server: https://kubernetes.default.svc
    namespace: ${ARGO_APP_NAMESPACE}
  syncPolicy:
    automated:
      prune: true
      selfHeal: true
    syncOptions:
      - CreateNamespace=true
EOF"
}

ensure_argocd_repo_connected() {
  local token
  [[ -n "${ARGO_GITHUB_REPO:-}" ]] || die "Argo CD repo is enabled but no GitHub repo was provided"
  ensure_gh_auth
  token="$(gh_token_for_argocd)"
  ensure_argocd_repo_secret "$ARGO_GITHUB_REPO" "$token"
  ensure_argocd_application "$ARGO_GITHUB_REPO"
}

collect_argo_config() {
  # If already configured, offer to keep or change
  if [[ -n "${ARGO_ENABLED:-}" ]] && [[ -n "${ARGO_GITHUB_REPO:-}" ]]; then
    if prompt_yes_no "Argo CD already configured with ${ARGO_GITHUB_REPO}. Keep it?" "y"; then
      return 0
    fi
  fi

  echo
  echo "Argo CD lets you manage apps through Git. Push changes to"
  echo "your repo, Argo CD automatically updates the cluster."
  if prompt_yes_no "Install Argo CD and connect a GitHub repo?" "y"; then
    ARGO_ENABLED="yes"
    write_config
    echo
    echo "The repo should contain Kubernetes YAML files."
    prompt_with_default ARGO_GITHUB_REPO "GitHub repo (format: owner/repo)"
    ARGO_GITHUB_REPO="$(normalize_github_repo_url "${ARGO_GITHUB_REPO:-}")"
    write_config
    prompt_with_default ARGO_GITHUB_BRANCH "Branch to watch (usually main)"
    echo
    echo "Path to the folder inside your repo that contains"
    echo "Kubernetes manifests. Use '.' for the root."
    prompt_with_default ARGO_APP_PATH "Folder path in repo"
    echo
    echo "Namespace is like a folder for your app in Kubernetes."
    echo "Using the app name keeps things organized."
    prompt_with_default ARGO_APP_NAMESPACE "Namespace (e.g., pihole)"
    prompt_with_default ARGO_APP_NAME "App name in Argo CD"
    prompt_with_default ARGO_UI_NODEPORT "Port for Argo CD dashboard"
  else
    ARGO_ENABLED=""
    ARGO_GITHUB_REPO=""
    write_config
  fi
}

argocd_admin_password() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath='{.data.password}' 2>/dev/null | base64 -d" 2>/dev/null || echo "(not available yet)"
}

get_loadbalancer_ips() {
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl get svc -A -o jsonpath='{range .items[?(@.spec.type==\"LoadBalancer\")]}{.metadata.namespace}/{.metadata.name}: {.status.loadBalancer.ingress[0].ip}{\"\\n\"}{end}' 2>/dev/null" 2>/dev/null || true
}

cluster_summary() {
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo -e "${CYAN}        OSTRA Cluster Summary${RESET}"
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  echo -e "${YELLOW}🚀 K3s Server${RESET}"
  echo -e "   ${CYAN}https://${VM_IP_NODE_1}:6443${RESET}"
  echo ""
  echo -e "${YELLOW}🖥️  Nodes${RESET}"
  echo -e "   ${CYAN}Node 1:${RESET} ${VM_NAME_NODE_1} (${VM_IP_NODE_1})"
  echo -e "   ${CYAN}Node 2:${RESET} ${VM_NAME_NODE_2} (${VM_IP_NODE_2})"
  echo -e "   ${CYAN}Node 3:${RESET} ${VM_NAME_NODE_3} (${VM_IP_NODE_3})"
  echo ""
  echo -e "${YELLOW}🌐 Cluster Ingress (single IP for all apps)${RESET}"
  local traefik_ip
  traefik_ip="$(get_traefik_ip)"
  if [[ -n "$traefik_ip" ]]; then
    echo -e "   ${CYAN}http://${traefik_ip}${RESET} - Access all your apps here"
    echo ""
    echo -e "   ${YELLOW}To use hostnames (recommended):${RESET}"
    echo -e "   1. Set your DNS or /etc/hosts to point pihole.local to ${traefik_ip}"
    echo -e "   2. Then access Pi-hole at: ${CYAN}http://pihole.local${RESET}"
    echo ""
    echo -e "   ${YELLOW}Or access directly by IP (quick test):${RESET}"
    echo -e "   ${CYAN}http://${traefik_ip}${RESET} (you may need to add a Host header)"
  else
    echo -e "   ${YELLOW}(IP not assigned yet - check 'kubectl -n kube-system get svc traefik')${RESET}"
  fi
  echo ""
  echo -e "${YELLOW}💾 Longhorn UI${RESET}"
  echo -e "   ${CYAN}http://${VM_IP_NODE_1}:${LONGHORN_UI_NODEPORT}${RESET}"
  if argo_enabled; then
    echo ""
    echo -e "${YELLOW}⚓ Argo CD${RESET}"
    echo -e "   ${CYAN}UI:${RESET}      http://${VM_IP_NODE_1}:${ARGO_UI_NODEPORT}"
    echo -e "   ${CYAN}User:${RESET}    admin"
    echo -e "   ${CYAN}Pass:${RESET}    $(argocd_admin_password)"
    echo -e "   ${CYAN}Repo:${RESET}    ${ARGO_GITHUB_REPO}"
    echo -e "   ${CYAN}Branch:${RESET}  ${ARGO_GITHUB_BRANCH}"
    echo -e "   ${CYAN}Path:${RESET}    ${ARGO_APP_PATH}"
  fi

  local lb_ips
  lb_ips="$(get_loadbalancer_ips)"
  if [[ -n "$lb_ips" ]]; then
    echo ""
    echo -e "${YELLOW}🌐 LoadBalancer Services${RESET}"
    echo "$lb_ips" | while read -r line; do
      echo -e "   ${CYAN}$line${RESET}"
    done
  fi
  echo ""
  echo -e "${GREEN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
  echo ""
  guest_ssh "$VM_IP_NODE_1" "sudo kubectl get nodes -o wide"
}

run_longhorn_smoke_test() {
  log "Running Longhorn PVC smoke test"
  guest_ssh "$VM_IP_NODE_1" "cat <<'EOF' | sudo kubectl apply -f - >/dev/null
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: ostra-smoke-pvc
  namespace: default
spec:
  accessModes:
    - ReadWriteOnce
  storageClassName: longhorn
  resources:
    requests:
      storage: 1Gi
---
apiVersion: v1
kind: Pod
metadata:
  name: ostra-smoke-pod
  namespace: default
spec:
  restartPolicy: Never
  containers:
    - name: smoke
      image: busybox:1.36
      command: ['sh', '-c', 'echo ostra > /data/check.txt && sleep 15']
      volumeMounts:
        - name: data
          mountPath: /data
  volumes:
    - name: data
      persistentVolumeClaim:
        claimName: ostra-smoke-pvc
EOF
sudo kubectl wait --for=condition=Ready pod/ostra-smoke-pod --timeout=180s >/dev/null
sudo kubectl exec ostra-smoke-pod -- cat /data/check.txt | grep -q '^ostra$'
sudo kubectl delete pod/ostra-smoke-pod --wait=true >/dev/null
sudo kubectl delete pvc/ostra-smoke-pvc --wait=false >/dev/null || true"
}

ensure_vm_on_node() {
  local idx="$1"
  local proxmox_ip_var="PROXMOX_NODE_${idx}_IP"
  local proxmox_name_var="PROXMOX_NODE_${idx}_NAME"
  local template_vmid_var="TEMPLATE_VMID_NODE_${idx}"
  local vmid_var="VMID_NODE_${idx}"
  local name_var="VM_NAME_NODE_${idx}"
  local guest_ip_var="VM_IP_NODE_${idx}"
  local vcpus_var="VM_NODE_${idx}_VCPUS"
  local ram_var="VM_NODE_${idx}_RAM_MB"
  local proxmox_ip="${!proxmox_ip_var}"
  local proxmox_name="${!proxmox_name_var}"
  local template_vmid="${!template_vmid_var}"
  local vmid="${!vmid_var}"
  local vm_name="${!name_var}"
  local guest_ip="${!guest_ip_var}"
  local vcpus="${!vcpus_var}"
  local ram_mb="${!ram_var}"
  local guest_user storage remote_key_file

  guest_user="$(vm_guest_user)"

  local changed=0

  if vm_exists_on_node "$proxmox_ip" "$vmid"; then
    log "VM ${vm_name} already exists on ${proxmox_name}; checking config"
  else
    storage="$(configured_vm_storage_target "$idx")"
    log "Cloning VM ${vm_name} on ${proxmox_name} from template ${template_vmid} to storage ${storage}"
    ssh_node "$proxmox_ip" "qm clone ${template_vmid} ${vmid} --name ${vm_name} --full 1 --storage ${storage}"
    changed=1
  fi

  storage="$(configured_vm_storage_target "$idx")"
  [[ -n "$storage" ]] || die "Could not find image-capable storage on ${proxmox_name}"

  if vm_needs_reconfig "$idx"; then
    remote_key_file="$(install_ssh_key_snippet_on_node "$proxmox_ip")"
    ssh_node "$proxmox_ip" "qm set ${vmid} --cores ${vcpus} --memory ${ram_mb} --ciuser ${guest_user} --sshkeys ${remote_key_file} --ipconfig0 ip=${guest_ip}/${CIDR},gw=${GATEWAY} --net0 virtio,bridge=${BRIDGE} --agent enabled=1 --vga std --delete serial0 >/dev/null 2>&1 || qm set ${vmid} --cores ${vcpus} --memory ${ram_mb} --ciuser ${guest_user} --sshkeys ${remote_key_file} --ipconfig0 ip=${guest_ip}/${CIDR},gw=${GATEWAY} --net0 virtio,bridge=${BRIDGE} --agent enabled=1 --vga std"
    ssh_node "$proxmox_ip" "qm cloudinit update ${vmid}"
    ssh_node "$proxmox_ip" "rm -f ${remote_key_file}"
    changed=1
  fi

  ssh_node "$proxmox_ip" "qm resize ${vmid} scsi0 ${VM_DISK_GB}G >/dev/null 2>&1 || true"
  ssh_node "$proxmox_ip" "qm start ${vmid} >/dev/null 2>&1 || true"
  if (( changed == 1 )); then
    ssh_node "$proxmox_ip" "qm reboot ${vmid} >/dev/null 2>&1 || qm reset ${vmid} >/dev/null 2>&1 || true"
  fi
}

ensure_all_vms() {
  ensure_ssh_public_key
  ensure_vm_on_node 1
  ensure_vm_on_node 2
  ensure_vm_on_node 3
}

prompt_with_default() {
  local var_name="$1"
  local prompt_text="$2"
  local current_value="${!var_name:-}"
  local input=""

  if ! has_tty; then
    return 0
  fi

  if [[ -n "$current_value" ]]; then
    read -r -p "$prompt_text [$current_value]: " input </dev/tty || true
    printf -v "$var_name" '%s' "${input:-$current_value}"
  else
    read -r -p "$prompt_text: " input </dev/tty || true
    printf -v "$var_name" '%s' "$input"
  fi

  write_config
}

prompt_yes_no() {
  local prompt_text="$1"
  local default_answer="${2:-y}"
  local input=""

  if ! has_tty; then
    [[ "$default_answer" == "y" ]]
    return
  fi

  if [[ "$default_answer" == "y" ]]; then
    read -r -p "$prompt_text [Y/n]: " input </dev/tty || true
    [[ -z "$input" || "$input" =~ ^[Yy]$ ]]
  else
    read -r -p "$prompt_text [y/N]: " input </dev/tty || true
    [[ "$input" =~ ^[Yy]$ ]]
  fi
}

valid_ipv4() {
  local ip="$1"
  [[ "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]] || return 1
  local IFS=.
  read -r o1 o2 o3 o4 <<< "$ip"
  for octet in "$o1" "$o2" "$o3" "$o4"; do
    (( octet >= 0 && octet <= 255 )) || return 1
  done
}

same_subnet_prefix_3() {
  local ip="$1"
  IFS=. read -r a b c _ <<< "$ip"
  echo "$a.$b.$c"
}

derive_gateway_if_missing() {
  if [[ -z "${GATEWAY:-}" ]] && [[ -n "${PROXMOX_NODE_1_IP:-}" ]]; then
    GATEWAY="$(same_subnet_prefix_3 "$PROXMOX_NODE_1_IP").1"
  fi
}

validate_config() {
  local missing=0
  local idx ip_var ip_value

  [[ "${ARGO_UI_NODEPORT:-30081}" =~ ^[0-9]+$ ]] || { echo "- ARGO_UI_NODEPORT must be numeric" >&2; missing=1; }

  for idx in 1 2 3; do
    ip_var="PROXMOX_NODE_${idx}_IP"
    ip_value="${!ip_var:-}"
    if [[ -z "$ip_value" ]]; then
      echo "- missing ${ip_var}" >&2
      missing=1
    elif ! valid_ipv4 "$ip_value"; then
      echo "- invalid ${ip_var}: $ip_value" >&2
      missing=1
    fi
  done

  [[ -n "${PROXMOX_SSH_USER:-}" ]] || { echo "- missing PROXMOX_SSH_USER" >&2; missing=1; }
  [[ -n "${BRIDGE:-}" ]] || { echo "- missing BRIDGE" >&2; missing=1; }
  [[ -n "${GATEWAY:-}" ]] || { echo "- missing GATEWAY" >&2; missing=1; }
  [[ -n "${CIDR:-}" ]] || { echo "- missing CIDR" >&2; missing=1; }

  if [[ -n "${STORAGE_ONLY_NODE_INDEX:-}" ]] && [[ ! "${STORAGE_ONLY_NODE_INDEX}" =~ ^[123]$ ]]; then
    echo "- STORAGE_ONLY_NODE_INDEX must be 1, 2, 3, or empty" >&2
    missing=1
  fi

  (( missing == 0 ))
}

collect_config_interactively() {
  echo
  echo "=== Proxmox Connection ==="
  echo "These are your 3 Proxmox nodes that will host the VMs"
  prompt_with_default PROXMOX_SSH_USER "SSH user for Proxmox (usually root)"
  prompt_with_default PROXMOX_NODE_1_NAME "Name of your strongest node (e.g., node1)"
  prompt_with_default PROXMOX_NODE_1_IP "IP address of node 1"
  prompt_with_default PROXMOX_NODE_2_NAME "Name of node 2 (e.g., node2)"
  prompt_with_default PROXMOX_NODE_2_IP "IP address of node 2"
  prompt_with_default PROXMOX_NODE_3_NAME "Name of node 3 (e.g., node3)"
  prompt_with_default PROXMOX_NODE_3_IP "IP address of node 3"
  derive_gateway_if_missing
  write_config
  
  echo
  echo "=== Network Settings ==="
  echo "These should match your existing network"
  prompt_with_default BRIDGE "Network bridge (usually vmbr0)"
  prompt_with_default GATEWAY "Gateway IP (usually your router)"
  prompt_with_default CIDR "Network CIDR (usually 24)"
  
  echo
  echo "=== Virtual Machines ==="
  echo "These VMs will run your Kubernetes cluster"
  prompt_with_default VM_OS "VM operating system"
  prompt_with_default VM_DISK_GB "Disk size per VM in GB"
  
  echo
  echo "=== Kubernetes Versions ==="
  echo "Pinning versions makes the cluster reproducible"
  prompt_with_default K3S_VERSION "K3s version"
  prompt_with_default LONGHORN_VERSION "Longhorn version (storage system)"
  prompt_with_default LONGHORN_UI_NODEPORT "Port for Longhorn dashboard"
  
  echo
  echo "=== Cluster Access (MetalLB) ==="
  echo "This creates ONE stable IP for your entire cluster. You'll"
  echo "access Pi-hole, Grafana, and all future apps through this"
  echo "single IP using different hostnames (pihole.local, etc)."
  echo ""
  echo "Pick a small IP range OUTSIDE your router's DHCP pool."
  echo "Example: if DHCP gives .100-.200, use .240-.250"
  prompt_with_default METALLB_VERSION "MetalLB version"
  prompt_with_default METALLB_IP_RANGE_START "First IP for cluster (e.g., 192.168.1.240)"
  prompt_with_default METALLB_IP_RANGE_END "Last IP for cluster (e.g., 192.168.1.250)"
  
  echo
  echo "=== Argo CD (Git-Based Deployment) ==="
  echo "Argo CD watches your Git repo and automatically deploys"
  echo "any changes you push. Edit files in Git, they go live."
  prompt_with_default ARGO_VERSION "Argo CD version"
  prompt_with_default ARGO_UI_NODEPORT "Argo CD UI node port"
  prompt_with_default VM_NODE_1_VCPUS "Node 1 VM vCPUs"
  prompt_with_default VM_NODE_1_RAM_MB "Node 1 VM RAM (MB)"
  prompt_with_default VM_NODE_2_VCPUS "Node 2 VM vCPUs"
  prompt_with_default VM_NODE_2_RAM_MB "Node 2 VM RAM (MB)"
  prompt_with_default VM_NODE_3_VCPUS "Node 3 VM vCPUs"
  prompt_with_default VM_NODE_3_RAM_MB "Node 3 VM RAM (MB)"
  prompt_with_default PROXMOX_NODE_1_STORAGE "Node 1 storage target (blank = auto)"
  prompt_with_default PROXMOX_NODE_2_STORAGE "Node 2 storage target (blank = auto)"
  prompt_with_default PROXMOX_NODE_3_STORAGE "Node 3 storage target (blank = auto)"
  if prompt_yes_no "Do you want one node to be storage-only (won't run normal workloads/pods)?" "n"; then
    prompt_with_default STORAGE_ONLY_NODE_INDEX "Storage-only node index (1-3)"
  else
    STORAGE_ONLY_NODE_INDEX=""
    write_config
  fi

  collect_argo_config
}

ensure_config_loaded() {
  ensure_dirs
  save_default_config_if_missing
  save_default_state_if_missing
  load_env_file "$CONFIG_FILE"
  load_env_file "$STATE_FILE"
}

ensure_config_ready() {
  local prompt_mode="${1:-ask}"

  ensure_config_loaded
  derive_gateway_if_missing

  if [[ "$prompt_mode" == "ask" ]] && has_tty; then
    if prompt_yes_no "Review/edit OSTRA config?" "y"; then
      collect_config_interactively
      derive_gateway_if_missing
      write_config
      log "Saved config to $CONFIG_FILE"
    fi
  fi

  validate_config || die "Config is incomplete. Run: ./ostra.sh config"
}

summarize_config() {
  cat <<EOF
Configured Proxmox nodes:
- 1: ${PROXMOX_NODE_1_NAME:-node1} (${PROXMOX_NODE_1_IP:-unset})
- 2: ${PROXMOX_NODE_2_NAME:-node2} (${PROXMOX_NODE_2_IP:-unset})
- 3: ${PROXMOX_NODE_3_NAME:-node3} (${PROXMOX_NODE_3_IP:-unset})

Cluster defaults:
- SSH user: ${PROXMOX_SSH_USER:-root}
- Bridge: ${BRIDGE:-vmbr0}
- Gateway: ${GATEWAY:-unset}
- CIDR: ${CIDR:-24}
- VM OS: ${VM_OS:-debian-12}
- VM disk: ${VM_DISK_GB:-64} GB
- K3s version: ${K3S_VERSION:-v1.32.4+k3s1}
- Longhorn version: ${LONGHORN_VERSION:-v1.9.1}
- Longhorn UI node port: ${LONGHORN_UI_NODEPORT:-30080}
- MetalLB version: ${METALLB_VERSION:-v0.14.9}
- MetalLB IP range: ${METALLB_IP_RANGE_START:-unset} - ${METALLB_IP_RANGE_END:-unset}
- Argo CD version: ${ARGO_VERSION:-v2.14.11}
- Argo CD UI node port: ${ARGO_UI_NODEPORT:-30081}
- Storage target node 1: ${PROXMOX_NODE_1_STORAGE:-auto}
- Storage target node 2: ${PROXMOX_NODE_2_STORAGE:-auto}
- Storage target node 3: ${PROXMOX_NODE_3_STORAGE:-auto}
- Storage-only node index: ${STORAGE_ONLY_NODE_INDEX:-none}
EOF
}

summarize_state() {
  cat <<EOF
Generated state:
- Template VMID node 1: ${TEMPLATE_VMID_NODE_1:-unset}
- Template VMID node 2: ${TEMPLATE_VMID_NODE_2:-unset}
- Template VMID node 3: ${TEMPLATE_VMID_NODE_3:-unset}
- VMID node 1: ${VMID_NODE_1:-unset}
- VMID node 2: ${VMID_NODE_2:-unset}
- VMID node 3: ${VMID_NODE_3:-unset}
- VM IP node 1: ${VM_IP_NODE_1:-unset}
- VM IP node 2: ${VM_IP_NODE_2:-unset}
- VM IP node 3: ${VM_IP_NODE_3:-unset}
- VM name node 1: ${VM_NAME_NODE_1:-unset}
- VM name node 2: ${VM_NAME_NODE_2:-unset}
- VM name node 3: ${VM_NAME_NODE_3:-unset}
- K3s token: ${K3S_TOKEN:+set}
EOF
}

run_reverse_flow() {
  ensure_config_ready "ask"
  write_config

  echo
  if [[ "${OSTRA_FORCE:-}" == "1" ]]; then
    log "Force mode enabled — running full bootstrap"
  else
    log "Checking cluster state (reverse order)"
  fi
  echo

  # Level 6: Check if Argo CD app is deployed with correct repo
  if [[ "${OSTRA_FORCE:-}" != "1" ]] && argo_enabled && k3s_server_ready 2>/dev/null && argocd_installed 2>/dev/null; then
    local current_repo
    current_repo="$(guest_ssh "$VM_IP_NODE_1" "sudo kubectl -n argocd get application ${ARGO_APP_NAME} -o jsonpath='{.spec.source.repoURL}' 2>/dev/null" 2>/dev/null || true)"
    if [[ "$current_repo" == *"${ARGO_GITHUB_REPO}"* ]]; then
      log "Argo CD app '${ARGO_APP_NAME}' already deployed from ${ARGO_GITHUB_REPO}"
      run_longhorn_smoke_test
      echo
      cluster_summary
      return 0
    fi
  fi

  # Level 5: Check Argo CD install
  if [[ "${OSTRA_FORCE:-}" != "1" ]] && argo_enabled; then
    if k3s_server_ready 2>/dev/null && argocd_installed 2>/dev/null; then
      log "Argo CD already installed"
    else
      log "Argo CD needed but cluster not ready, continuing down..."
    fi
  fi

  # Level 4: Check MetalLB
  if [[ "${OSTRA_FORCE:-}" != "1" ]] && k3s_server_ready 2>/dev/null && metallb_installed 2>/dev/null && [[ -n "$(get_traefik_ip)" ]]; then
    log "MetalLB and ingress controller ready"
  else
    log "MetalLB or ingress not ready, continuing down..."
  fi

  # Level 3: Check Longhorn
  if [[ "${OSTRA_FORCE:-}" != "1" ]] && k3s_server_ready 2>/dev/null && longhorn_installed 2>/dev/null; then
    log "Longhorn already installed"
  else
    log "Longhorn not ready, continuing down..."
  fi

  # Level 2: Check K3s cluster
  if [[ "${OSTRA_FORCE:-}" != "1" ]] && k3s_server_ready 2>/dev/null; then
    log "K3s cluster already ready"
  else
    log "K3s cluster not ready, continuing down..."
  fi

  # Level 2: Check guest SSH (VMs exist and booted)
  if guest_reachable "$VM_IP_NODE_1" 2>/dev/null && \
     guest_reachable "$VM_IP_NODE_2" 2>/dev/null && \
     guest_reachable "$VM_IP_NODE_3" 2>/dev/null; then
    log "All guests reachable via SSH"
  else
    log "Guests not all reachable, continuing down..."
  fi

  # Level 1: Check Proxmox connectivity and infra
  log "Checking Proxmox SSH connectivity"
  ensure_proxmox_connectivity

  log "Assigning stable template VMIDs, VM IDs, names, and guest IPs"
  assign_state_defaults

  echo
  summarize_config
  echo
  summarize_state
  echo
  summarize_vm_targets
  echo
  report_vm_presence
  echo

  log "Ensuring one Debian template exists per Proxmox node"
  ensure_all_templates
  echo

  log "Ensuring target VMs exist and are configured"
  ensure_all_vms
  echo
  report_vm_presence
  echo

  log "Waiting for guest SSH readiness"
  ensure_all_guest_ssh
  echo

  log "Ensuring K3s cluster is installed"
  ensure_k3s_cluster
  echo

  log "Ensuring MetalLB is installed"
  ensure_metallb
  echo

  log "Exposing ingress controller for single-cluster IP access"
  ensure_traefik_loadbalancer
  echo

  log "Ensuring Longhorn is installed"
  ensure_longhorn
  echo

  if argo_enabled; then
    log "Ensuring Argo CD is installed"
    ensure_argocd
    ensure_argocd_repo_connected
    echo
  fi

  run_longhorn_smoke_test
  echo

  cluster_summary
}

main() {
  if [[ $# -gt 0 ]]; then
    case "${1:-}" in
      -h|--help|help)
        usage
        exit 0
        ;;
      *)
        die "OSTRA does not accept command arguments"
        ;;
    esac
  fi

  run_reverse_flow
}

main "$@"
