#!/usr/bin/env bash
# Copyright 2026 Lusoris
# 05-hypervisor-agents.sh — Multi-hypervisor guest agents and Unraid VirtFS integration
# Coexistence of QEMU guest agent, VMware open-vm-tools, and Unraid host sharing.
set -euo pipefail

install_hypervisor_packages() {
  echo "==> Installing hypervisor guest agents and ACPI power management..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    qemu-guest-agent \
    open-vm-tools \
    spice-vdagent \
    acpid || true

  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    hyperv-daemons 2>/dev/null || true
}

configure_unraid_virtfs() {
  echo "==> Enabling Unraid virtiofs and 9p host-sharing kernel modules..."
  cat <<'EOF' | sudo tee /etc/modules-load.d/unraid-virtfs.conf
# Unraid & KVM Host-to-Guest Directory Passthrough
9p
9pnet
9pnet_virtio
virtiofs
EOF

  sudo modprobe 9p 2>/dev/null || true
  sudo modprobe 9pnet 2>/dev/null || true
  sudo modprobe 9pnet_virtio 2>/dev/null || true
  sudo modprobe virtiofs 2>/dev/null || true
}

configure_agent_services() {
  echo "==> Enabling hypervisor daemons with dormant condition guards..."
  sudo systemctl enable qemu-guest-agent.service 2>/dev/null || true
  sudo systemctl enable open-vm-tools.service 2>/dev/null || true
  sudo systemctl enable acpid.service 2>/dev/null || true
  sudo systemctl enable spice-vdagent.service 2>/dev/null || true

  sudo mkdir -p /etc/systemd/system/open-vm-tools.service.d
  cat <<'EOF' | sudo tee /etc/systemd/system/open-vm-tools.service.d/10-condition-virt.conf
[Unit]
ConditionVirtualization=vmware
EOF
}

main() {
  install_hypervisor_packages
  configure_unraid_virtfs
  configure_agent_services
  echo "==> 05-hypervisor-agents: Complete."
}

main "$@"
