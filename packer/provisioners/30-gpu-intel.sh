#!/usr/bin/env bash
# 30-gpu-intel.sh — Intel Arc, Flex, and UHD/Iris Xe GPU acceleration stack
# Installs Level Zero, oneVPL, Intel Media VA-API driver, and OpenCL compute.
set -euo pipefail

install_intel_drivers() {
  echo "==> Installing Intel Media Driver and Level Zero compute runtime..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    intel-media-va-driver-non-free \
    libva2 \
    vainfo \
    intel-opencl-icd \
    clinfo \
    libze1 \
    libze-intel-gpu1 \
    libvpl2 \
    hwinfo
}

configure_intel_permissions() {
  echo "==> Configuring udev rules and user groups for Intel GPU devices..."
  # Ensure render group exists and standard users have access
  sudo usermod -aG render,video ubuntu || true

  cat <<'EOF' | sudo tee /etc/udev/rules.d/60-intel-gpu.rules
# Allow render group direct access to DRI nodes
KERNEL=="card*", SUBSYSTEM=="drm", GROUP="video", MODE="0660"
KERNEL=="renderD*", SUBSYSTEM=="drm", GROUP="render", MODE="0666"
EOF
}

main() {
  install_intel_drivers
  configure_intel_permissions
  echo "==> 30-gpu-intel: Complete."
}

main "$@"
