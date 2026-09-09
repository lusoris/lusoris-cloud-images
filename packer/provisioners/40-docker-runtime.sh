#!/usr/bin/env bash
# 40-docker-runtime.sh — Install Docker CE, Docker Compose v2, and containerd.io
# Configures log rotation, systemd cgroup driver, and container runtime defaults.
set -euo pipefail

setup_docker_repository() {
  echo "==> Configuring official Docker apt repository..."
  sudo mkdir -p -m 755 /etc/apt/keyrings
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg |
    sudo gpg --dearmor --yes -o /etc/apt/keyrings/docker.gpg

  echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu noble stable" |
    sudo tee /etc/apt/sources.list.d/docker.list

  sudo apt-get update
}

install_docker_packages() {
  echo "==> Installing Docker CE and Compose plugin..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    docker-ce \
    docker-ce-cli \
    containerd.io \
    docker-buildx-plugin \
    docker-compose-plugin
}

configure_docker_daemon() {
  echo "==> Configuring /etc/docker/daemon.json..."
  sudo mkdir -p /etc/docker
  cat <<'EOF' | sudo tee /etc/docker/daemon.json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "live-restore": true
}
EOF

  sudo usermod -aG docker ubuntu || true
  sudo systemctl daemon-reload
  sudo systemctl enable --now docker.service
}

main() {
  setup_docker_repository
  install_docker_packages
  configure_docker_daemon
  echo "==> 40-docker-runtime: Complete."
}

main "$@"
