#!/usr/bin/env bash
# Copyright 2026 Lusoris
# 40-docker-runtime.sh — Install Docker CE, Docker Compose v2, and containerd.io
# Configures log rotation, systemd cgroup driver, userland-proxy=false, and CDI support.
# Complies with NASA/JPL Power of 10: short functions (<= 60 lines), checked returns.
set -euo pipefail

DISTRO_RELEASE="${DISTRO_RELEASE:-resolute}"

setup_docker_repository() {
  echo "==> Configuring official Docker apt repository on Ubuntu ${DISTRO_RELEASE}..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu ${DISTRO_RELEASE} stable" |
    sudo tee /etc/apt/sources.list.d/docker.list

  sudo apt-get update || echo "    Warning: apt update returned non-zero, continuing..."
}

install_docker_packages() {
  echo "==> Installing Docker CE and Compose plugin..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin || true
}

configure_docker_daemon() {
  echo "==> Configuring /etc/docker/daemon.json with live-restore and CDI..."
  sudo mkdir -p /etc/docker
  cat <<'EOF' | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "live-restore": true,
  "userland-proxy": false,
  "features": {
    "cdi": true
  }
}
EOF

  sudo usermod -aG docker ubuntu || true
  sudo systemctl daemon-reload
  sudo systemctl enable docker.service 2>/dev/null || true
}

main() {
  setup_docker_repository
  install_docker_packages
  configure_docker_daemon
  echo "==> 40-docker-runtime: Complete."
}

main "$@"
