#!/usr/bin/env bash
# 55-k8s-precache.sh — Pre-pull core DaemonSets and runtime images into containerd
# Image tags are injected dynamically from versions.json via Packer environment variables.
set -euo pipefail

PULL_IMAGES=(
  "${IMG_PAUSE:-registry.k8s.io/pause:3.10}"
  "${IMG_COREDNS:-registry.k8s.io/coredns/coredns:v1.12.0}"
  "${IMG_CILIUM:-quay.io/cilium/cilium:v1.17.1}"
  "${IMG_KUBE_VIP:-ghcr.io/kube-vip/kube-vip:v0.8.9}"
  "${IMG_NODE_EXPORTER:-prom/node-exporter:v1.9.0}"
)

precache_core_images() {
  echo "==> Pre-caching core Kubernetes images into containerd k8s.io namespace..."
  sudo systemctl start containerd

  for img in "${PULL_IMAGES[@]}"; do
    echo "    Pulling: ${img}"
    sudo ctr -n k8s.io images pull "${img}" || echo "    Warning: failed to pre-cache ${img}, continuing..."
  done
}

precache_flavor_specific_images() {
  local flavor="${FLAVOR:-}"
  echo "==> Checking hardware plugin images for '${flavor}'..."

  case "${flavor}" in
    *intel*)
      local intel_plugin="${IMG_INTEL_PLUGIN:-intel/intel-gpu-plugin:0.32.0}"
      echo "    Pulling Intel Device Plugin: ${intel_plugin}..."
      sudo ctr -n k8s.io images pull "${intel_plugin}" || true
      ;;
    *nvidia*)
      local nvidia_plugin="${IMG_NVIDIA_PLUGIN:-nvcr.io/nvidia/k8s-device-plugin:v0.17.0}"
      echo "    Pulling NVIDIA Device Plugin: ${nvidia_plugin}..."
      sudo ctr -n k8s.io images pull "${nvidia_plugin}" || true
      ;;
    *amd*)
      local amd_plugin="${IMG_AMD_PLUGIN:-rocm/k8s-device-plugin:v1.32.0}"
      echo "    Pulling AMD Device Plugin: ${amd_plugin}..."
      sudo ctr -n k8s.io images pull "${amd_plugin}" || true
      ;;
    *)
      echo "    No extra hardware daemonsets required for flavor '${flavor}'"
      ;;
  esac
}

main() {
  precache_core_images
  precache_flavor_specific_images
  echo "==> 55-k8s-precache: Complete."
}

main "$@"
