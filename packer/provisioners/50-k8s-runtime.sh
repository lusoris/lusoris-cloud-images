#!/usr/bin/env bash
# 50-k8s-runtime.sh — Install containerd CRI runtime and Kubernetes node components
# Consumes K8S_MAJOR_MINOR injected dynamically from versions.json.
set -euo pipefail

K8S_MAJOR_MINOR="${K8S_MAJOR_MINOR:-1.32}"

setup_containerd() {
  echo "==> Installing and configuring containerd..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends containerd

  sudo mkdir -p /etc/containerd
  sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null
  sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml

  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd
}

setup_kubernetes_packages() {
  echo "==> Setting up Kubernetes official apt repository (v${K8S_MAJOR_MINOR})..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL "https://pkgs.k8s.io/core:/stable:/v${K8S_MAJOR_MINOR}/deb/Release.key" |
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg

  echo "deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v${K8S_MAJOR_MINOR}/deb/ /" |
    sudo tee /etc/apt/sources.list.d/kubernetes.list

  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    kubelet \
    kubeadm \
    kubectl

  sudo apt-mark hold kubelet kubeadm kubectl
  sudo systemctl enable kubelet
}

main() {
  setup_containerd
  setup_kubernetes_packages
  echo "==> 50-k8s-runtime: Complete."
}

main "$@"
