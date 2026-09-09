#!/usr/bin/env bash
# 32-gpu-nvidia.sh — NVIDIA GPU driver hooks and NVIDIA Container Toolkit
# Configures headless driver repository and NVIDIA container runtime.
set -euo pipefail

setup_nvidia_repositories() {
  echo "==> Configuring NVIDIA Container Toolkit apt repository..."
  curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg

  curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
    sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
    sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

  sudo apt-get update
}

install_nvidia_toolkit() {
  echo "==> Installing nvidia-container-toolkit and utilities..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    nvidia-container-toolkit \
    hwinfo
}

configure_nvidia_container_runtime() {
  echo "==> Configuring NVIDIA runtime for containerd CDI..."
  # If containerd is already installed or will be installed, generate CDI specification
  if command -v nvidia-ctk >/dev/null 2>&1; then
    sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml || true
  fi

  # Ensure video and render permissions
  sudo usermod -aG render,video ubuntu || true
}

main() {
  setup_nvidia_repositories
  install_nvidia_toolkit
  configure_nvidia_container_runtime
  echo "==> 32-gpu-nvidia: Complete."
}

main "$@"
