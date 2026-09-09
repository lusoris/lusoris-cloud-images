#!/usr/bin/env bash
# 20-kernel-sysctl.sh — Configure networking, sysctl, kernel modules, and swap
# Prepared for high-performance cloud workloads and container runtimes.
set -euo pipefail

configure_sysctl() {
  echo "==> Setting system sysctl parameters..."
  cat <<'EOF' | sudo tee /etc/sysctl.d/99-lusoris.conf
# Network forwarding & container bridging
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# Filesystem watch limits
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288

# Memory virtual paging & swap
vm.swappiness = 0
vm.overcommit_memory = 1
EOF

  # Load modules required by bridge netfilter
  printf 'overlay\nbr_netfilter\n' | sudo tee /etc/modules-load.d/container-runtime.conf
  sudo modprobe overlay 2>/dev/null || true
  sudo modprobe br_netfilter 2>/dev/null || true
}

disable_swap() {
  echo "==> Permanently disabling and masking swap..."
  sudo sed -i '/\sswap\s/d' /etc/fstab || true
  sudo swapoff -a 2>/dev/null || true
  sudo systemctl mask swap.target 2>/dev/null || true
}

configure_unattended_upgrades() {
  echo "==> Configuring unattended security updates with kernel pin guard..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends unattended-upgrades

  cat <<'EOF' | sudo tee /etc/apt/apt.conf.d/20auto-upgrades
APT::Periodic::Update-Package-Lists "1";
APT::Periodic::Unattended-Upgrade "1";
EOF

  cat <<'EOF' | sudo tee /etc/apt/apt.conf.d/52unattended-upgrades-blacklist
Unattended-Upgrade::Package-Blacklist {
  "linux-image-*";
  "linux-headers-*";
  "containerd*";
  "kubelet";
  "kubeadm";
  "kubectl";
};
EOF
}

main() {
  configure_sysctl
  disable_swap
  configure_unattended_upgrades
  echo "==> 20-kernel-sysctl: Complete."
}

main "$@"
