#!/usr/bin/env bash
# 45-k8s-precache.sh — Pre-pull core DaemonSets and runtime images into containerd
# Eliminates container pull latency on initial node boot.
set -euo pipefail

PULL_IMAGES=(
  "registry.k8s.io/pause:3.10"
  "registry.k8s.io/coredns/coredns:v1.12.0"
  "quay.io/cilium/cilium:v1.17.1"
  "ghcr.io/kube-vip/kube-vip:v0.8.9"
  "prom/node-exporter:v1.9.0"
)

precache_core_images() {
  echo "==> Pre-caching core Kubernetes images into containerd k8s.io namespace..."
  # Ensure containerd is running for image pulling
  sudo systemctl start containerd

  for img in "${PULL_IMAGES[@]}"; do
    echo "    Pulling: ${img}"
    sudo ctr -n k8s.io images pull "${img}" || echo "    Warning: failed to pre-cache ${img}, continuing..."
  done
}

precache_flavor_specific_images() {
  local flavor="${FLAVOR:-}"
  echo "==> Checking flavor-specific images for '${flavor}'..."

  case "${flavor}" in
    *intel*)
      echo "    Pulling Intel Device Plugin..."
      sudo ctr -n k8s.io images pull "intel/intel-gpu-plugin:0.32.0" || true
      ;;
    *nvidia*)
      echo "    Pulling NVIDIA Device Plugin..."
      sudo ctr -n k8s.io images pull "nvcr.io/nvidia/k8s-device-plugin:v0.17.0" || true
      ;;
    *amd*)
      echo "    Pulling AMD Device Plugin..."
      sudo ctr -n k8s.io images pull "rocm/k8s-device-plugin:latest" || true
      ;;
    *)
      echo "    No extra hardware daemonsets required for flavor '${flavor}'"
      ;;
  esac
}

main() {
  precache_core_images
  precache_flavor_specific_images
  echo "==> 45-k8s-precache: Complete."
}

main "$@"
