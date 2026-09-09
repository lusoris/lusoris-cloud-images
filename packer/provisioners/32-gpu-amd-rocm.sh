#!/usr/bin/env bash
# 32-gpu-amd-rocm.sh — AMD ROCm compute runtime for AI/ML and GPU acceleration
# Configures ROCm repository, HIP runtime, rocBLAS, and /dev/kfd compute nodes.
set -euo pipefail

ROCM_VERSION="${ROCM_VERSION:-6.2}"

setup_rocm_repository() {
  echo "==> Configuring AMD ROCm apt repository (version: ${ROCM_VERSION})..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://repo.radeon.com/rocm/rocm.gpg |
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/rocm.gpg

  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/rocm.gpg] https://repo.radeon.com/rocm/apt/${ROCM_VERSION} noble main" |
    sudo tee /etc/apt/sources.list.d/rocm.list

  sudo apt-get update
}

install_rocm_packages() {
  echo "==> Installing ROCm HIP runtime and core compute libraries..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    rocm-hip-runtime \
    rocminfo \
    hwinfo
}

configure_rocm_permissions() {
  echo "==> Configuring AMD KFD compute permissions..."
  sudo usermod -aG render,video ubuntu || true

  cat <<'EOF' | sudo tee /etc/udev/rules.d/65-rocm-kfd.rules
# Allow render group direct access to AMD KFD compute hardware
KERNEL=="kfd", SUBSYSTEM=="kfd", GROUP="render", MODE="0666"
EOF
}

main() {
  setup_rocm_repository
  install_rocm_packages
  configure_rocm_permissions
  echo "==> 32-gpu-amd-rocm: Complete."
}

main "$@"
