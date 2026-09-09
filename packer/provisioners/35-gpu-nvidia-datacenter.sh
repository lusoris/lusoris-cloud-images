#!/usr/bin/env bash
# 35-gpu-nvidia-datacenter.sh — NVIDIA Datacenter (Hopper & Blackwell) driver stack
# Installs NVIDIA Open Kernel Modules, Fabric Manager for NVLink, and Container Toolkit.
set -euo pipefail

BASE_BRANCH="${NVIDIA_DATACENTER_BRANCH:-565}"

setup_datacenter_repositories() {
  echo "==> Configuring NVIDIA Datacenter & Container Toolkit repositories..."
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey |
    sudo gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list |
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' |
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

  sudo apt-get update
}

install_datacenter_driver_and_fabric() {
  echo "==> Installing NVIDIA Open Kernel Modules and Fabric Manager..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    nvidia-driver-"${BASE_BRANCH}"-open \
    nvidia-fabricmanager-"${BASE_BRANCH}" \
    nvidia-container-toolkit \
    hwinfo || {
    echo "    Warning: specific open branch unavailable, falling back to standard headless..."
    sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      nvidia-headless-"${BASE_BRANCH}" nvidia-container-toolkit hwinfo || true
  }

  sudo systemctl enable nvidia-fabricmanager.service 2>/dev/null || true
}

configure_datacenter_runtime() {
  echo "==> Configuring NVIDIA CDI and user permissions for datacenter nodes..."
  if command -v nvidia-ctk >/dev/null 2>&1; then
    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml || true
  fi
  sudo usermod -aG render,video ubuntu || true
}

main() {
  setup_datacenter_repositories
  install_datacenter_driver_and_fabric
  configure_datacenter_runtime
  echo "==> 35-gpu-nvidia-datacenter: Complete."
}

main "$@"
