#!/usr/bin/env bash
# 31-gpu-amd.sh — AMD Radeon and Ryzen APU GPU acceleration stack
# Installs Mesa Gallium radeonsi VA-API, RADV Vulkan drivers, and DRM runtime.
set -euo pipefail

install_amd_drivers() {
  echo "==> Installing AMD GPU drivers (Mesa VA-API, RADV Vulkan)..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    mesa-va-drivers \
    mesa-vulkan-drivers \
    libdrm-amdgpu1 \
    vainfo \
    vulkan-tools \
    hwinfo
}

configure_amd_permissions() {
  echo "==> Configuring udev rules and user groups for AMD GPU devices..."
  sudo usermod -aG render,video ubuntu || true

  cat <<'EOF' | sudo tee /etc/udev/rules.d/60-amd-gpu.rules
# Allow render group direct access to AMD DRI and KFD compute nodes
KERNEL=="card*", SUBSYSTEM=="drm", GROUP="video", MODE="0660"
KERNEL=="renderD*", SUBSYSTEM=="drm", GROUP="render", MODE="0666"
KERNEL=="kfd", SUBSYSTEM=="kfd", GROUP="render", MODE="0666"
EOF
}

main() {
  install_amd_drivers
  configure_amd_permissions
  echo "==> 31-gpu-amd: Complete."
}

main "$@"
