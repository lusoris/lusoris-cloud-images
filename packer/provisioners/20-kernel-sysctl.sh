#!/usr/bin/env bash
# 20-kernel-sysctl.sh — High-performance network sysctl, CIS baseline, and swap disable
# Configures BBR congestion control, bridge netfilter, and CIS benchmark security parameters.
set -euo pipefail

configure_sysctl_and_bbr() {
  echo "==> Setting high-performance network, bridging, and BBR parameters..."
  cat <<'EOF' | sudo tee /etc/sysctl.d/99-lusoris.conf
# Network forwarding & container bridging
net.bridge.bridge-nf-call-iptables = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward = 1
net.ipv6.conf.all.forwarding = 1

# BBR Congestion Control & High-Throughput Buffers
net.core.default_qdisc = fq
net.ipv4.tcp_congestion_control = bbr
net.core.rmem_max = 16777216
net.core.wmem_max = 16777216

# Filesystem watch limits & virtual memory
fs.inotify.max_user_instances = 8192
fs.inotify.max_user_watches = 524288
vm.swappiness = 0
vm.overcommit_memory = 1

# CIS Benchmark Level 1 Hardening
fs.suid_dumpable = 0
fs.protected_hardlinks = 1
fs.protected_symlinks = 1
kernel.randomize_va_space = 2
kernel.kptr_restrict = 2
kernel.dmesg_restrict = 1
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.icmp_echo_ignore_broadcasts = 1
EOF

  printf 'overlay\nbr_netfilter\ntcp_bbr\n' | sudo tee /etc/modules-load.d/container-runtime.conf
  sudo modprobe overlay 2>/dev/null || true
  sudo modprobe br_netfilter 2>/dev/null || true
  sudo modprobe tcp_bbr 2>/dev/null || true
}

blacklist_uncommon_protocols() {
  echo "==> Blacklisting unused legacy and uncommon network protocols..."
  cat <<'EOF' | sudo tee /etc/modprobe.d/blacklist-uncommon.conf
install dccp /bin/true
install sctp /bin/true
install rds /bin/true
install tipc /bin/true
install cramfs /bin/true
install freevxfs /bin/true
install jffs2 /bin/true
install hfs /bin/true
install hfsplus /bin/true
EOF
}

disable_swap_and_configure_upgrades() {
  echo "==> Disabling swap and configuring unattended security updates..."
  sudo sed -i '/\sswap\s/d' /etc/fstab || true
  sudo swapoff -a 2>/dev/null || true
  sudo systemctl mask swap.target 2>/dev/null || true

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
  configure_sysctl_and_bbr
  blacklist_uncommon_protocols
  disable_swap_and_configure_upgrades
  echo "==> 20-kernel-sysctl: Complete."
}

main "$@"
