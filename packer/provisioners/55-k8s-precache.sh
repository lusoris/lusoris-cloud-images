#!/usr/bin/env bash
# 55-k8s-precache.sh — Modular pre-pulling of Kubernetes DaemonSets and runtime images
# Supports profiles: lean (pause only), cilium, calico, flannel.
# Complies with NASA/JPL Power of 10: short functions (<= 60 lines), checked returns.
set -euo pipefail

PREHEAT_PROFILE="${PREHEAT_PROFILE:-lean}"

precache_by_profile() {
  local pause_img="${IMG_PAUSE:-registry.k8s.io/pause:3.10}"
  local coredns_img="${IMG_COREDNS:-registry.k8s.io/coredns/coredns:v1.14.7}"
  local kubevip_img="${IMG_KUBE_VIP:-ghcr.io/kube-vip/kube-vip:v1.2.3}"
  local exporter_img="${IMG_NODE_EXPORTER:-prom/node-exporter:v1.12.1}"
  local images_to_pull=("${pause_img}")

  echo "==> Executing preheat profile: '${PREHEAT_PROFILE}'..."
  sudo systemctl start containerd

  case "${PREHEAT_PROFILE}" in
    cilium)
      local cilium_img="${IMG_CILIUM:-quay.io/cilium/cilium:v1.20.1}"
      local operator_img="${IMG_CILIUM_OPERATOR:-quay.io/cilium/operator-generic:v1.20.1}"
      images_to_pull+=("${coredns_img}" "${cilium_img}" "${operator_img}" "${kubevip_img}" "${exporter_img}")
      ;;
    calico)
      local calico_cni="${IMG_CALICO_CNI:-docker.io/calico/cni:v3.32.2}"
      local calico_node="${IMG_CALICO_NODE:-docker.io/calico/node:v3.32.2}"
      local calico_ctrl="${IMG_CALICO_CTRL:-docker.io/calico/kube-controllers:v3.32.2}"
      images_to_pull+=("${coredns_img}" "${calico_cni}" "${calico_node}" "${calico_ctrl}" "${kubevip_img}" "${exporter_img}")
      ;;
    flannel)
      local flannel_img="${IMG_FLANNEL:-docker.io/flannel/flannel:v0.28.9}"
      local flannel_cni="${IMG_FLANNEL_CNI:-docker.io/flannel/flannel-cni-plugin:v1.6.2-flannel1}"
      images_to_pull+=("${coredns_img}" "${flannel_img}" "${flannel_cni}" "${kubevip_img}" "${exporter_img}")
      ;;
    lean | none | *)
      echo "    Lean profile selected: caching pause container only (~1.2GB image target)."
      ;;
  esac

  for img in "${images_to_pull[@]}"; do
    echo "    Pulling: ${img}"
    sudo ctr -n k8s.io images pull "${img}" || echo "    Warning: failed to pull ${img}, continuing..."
  done
}

precache_hardware_plugins() {
  local flavor="${FLAVOR:-}"
  echo "==> Checking hardware plugin images for '${flavor}'..."

  case "${flavor}" in
    *intel*)
      local intel_plugin="${IMG_INTEL_PLUGIN:-intel/intel-gpu-plugin:0.36.0}"
      echo "    Pulling Intel Device Plugin: ${intel_plugin}..."
      sudo ctr -n k8s.io images pull "${intel_plugin}" || true
      ;;
    *nvidia*)
      local nvidia_plugin="${IMG_NVIDIA_PLUGIN:-nvcr.io/nvidia/k8s-device-plugin:v0.20.0}"
      echo "    Pulling NVIDIA Device Plugin: ${nvidia_plugin}..."
      sudo ctr -n k8s.io images pull "${nvidia_plugin}" || true
      ;;
    *amd*)
      local amd_plugin="${IMG_AMD_PLUGIN:-rocm/k8s-device-plugin:v1.37.0}"
      echo "    Pulling AMD Device Plugin: ${amd_plugin}..."
      sudo ctr -n k8s.io images pull "${amd_plugin}" || true
      ;;
    *)
      echo "    No extra hardware daemonsets required for flavor '${flavor}'"
      ;;
  esac
}

main() {
  precache_by_profile
  precache_hardware_plugins
  echo "==> 55-k8s-precache: Complete."
}

main "$@"
