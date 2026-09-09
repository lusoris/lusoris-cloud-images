#!/usr/bin/env bash
# 50-k8s-runtime.sh — Install containerd CRI runtime and Kubernetes node components
# Consumes K8S_MAJOR_MINOR injected dynamically from versions.json (Ubuntu 26.04).
# Complies with NASA/JPL Power of 10: short functions (<= 60 lines), checked returns.
set -euo pipefail

K8S_MAJOR_MINOR="${K8S_MAJOR_MINOR:-1.37}"
IMG_PAUSE="${IMG_PAUSE:-registry.k8s.io/pause:3.10}"

setup_containerd() {
  echo "==> Installing and configuring containerd 2.3+ with CRI standards..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends containerd

  sudo mkdir -p /etc/containerd
  sudo containerd config default | sudo tee /etc/containerd/config.toml >/dev/null

  # Enable systemd cgroup driver and set pause sandbox image
  sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
  sudo sed -i "s|sandbox_image = .*|sandbox_image = \"${IMG_PAUSE}\"|" /etc/containerd/config.toml
  sudo sed -i 's/discard_unpacked_layers = false/discard_unpacked_layers = true/' /etc/containerd/config.toml

  # Configure default crictl endpoint
  cat <<'EOF' | sudo tee /etc/crictl.yaml
runtime-endpoint: unix:///run/containerd/containerd.sock
image-endpoint: unix:///run/containerd/containerd.sock
timeout: 10
debug: false
EOF

  sudo systemctl daemon-reload
  sudo systemctl enable --now containerd
}

setup_kubernetes_packages() {
  echo "==> Setting up Kubernetes official repository (v${K8S_MAJOR_MINOR})..."
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
