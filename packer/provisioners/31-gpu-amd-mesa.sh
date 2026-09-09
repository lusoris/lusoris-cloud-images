#!/usr/bin/env bash
# 31-gpu-amd-mesa.sh — AMD Radeon and Ryzen APU Mesa VA-API and Vulkan stack
# Installs Mesa Gallium radeonsi VA-API, RADV Vulkan drivers, and DRM runtime.
set -euo pipefail

install_amd_mesa_drivers() {
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
# Direct access for render group to AMD DRI graphics nodes
KERNEL=="card*", SUBSYSTEM=="drm", GROUP="video", MODE="0660"
KERNEL=="renderD*", SUBSYSTEM=="drm", GROUP="render", MODE="0666"
EOF
}

main() {
  install_amd_mesa_drivers
  configure_amd_permissions
  echo "==> 31-gpu-amd-mesa: Complete."
}

main "$@"
