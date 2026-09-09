#!/usr/bin/env bash
# 41-podman-runtime.sh — Install Podman 5.x, Buildah, Skopeo, and Quadlet systemd support
# Configures daemonless, rootless container stack with automated Quadlet generators.
set -euo pipefail

install_podman_packages() {
  echo "==> Installing Podman, Buildah, Skopeo, and crun..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    podman \
    buildah \
    skopeo \
    crun \
    slirp4netns \
    uidmap
}

configure_quadlet_and_rootless() {
  echo "==> Configuring Quadlet systemd directory and rootless subordinate IDs..."
  sudo mkdir -p /etc/containers/systemd
  sudo mkdir -p /home/ubuntu/.config/containers/systemd

  if ! grep -q "^ubuntu:" /etc/subuid 2>/dev/null; then
    echo "ubuntu:100000:65536" | sudo tee -a /etc/subuid
  fi
  if ! grep -q "^ubuntu:" /etc/subgid 2>/dev/null; then
    echo "ubuntu:100000:65536" | sudo tee -a /etc/subgid
  fi

  sudo chown -R ubuntu:ubuntu /home/ubuntu/.config 2>/dev/null || true
}

main() {
  install_podman_packages
  configure_quadlet_and_rootless
  echo "==> 41-podman-runtime: Complete."
}

main "$@"
