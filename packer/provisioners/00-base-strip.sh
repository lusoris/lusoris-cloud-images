#!/usr/bin/env bash
# 00-base-strip.sh — Strip distro bloat and install minimal base packages
# Complies with NASA/JPL Power of 10: short functions, checked returns.
set -euo pipefail

strip_documentation_paths() {
  echo "==> Configuring dpkg path exclusions for docs and locales..."
  echo 'path-exclude=/usr/share/doc/*' | sudo tee /etc/dpkg/dpkg.cfg.d/01_nodoc
  echo 'path-exclude=/usr/share/man/*' | sudo tee -a /etc/dpkg/dpkg.cfg.d/01_nodoc
  echo 'path-exclude=/usr/share/info/*' | sudo tee -a /etc/dpkg/dpkg.cfg.d/01_nodoc
  echo 'path-exclude=/usr/share/locale/*' | sudo tee /etc/dpkg/dpkg.cfg.d/01_nolocale
  echo 'path-include=/usr/share/locale/en*' | sudo tee -a /etc/dpkg/dpkg.cfg.d/01_nolocale
}

purge_distro_bloat() {
  echo "==> Purging snapd, telemetry, and unneeded daemons..."
  sudo systemctl disable --now snapd.service snapd.socket snapd.seeded.service 2>/dev/null || true

  sudo DEBIAN_FRONTEND=noninteractive apt-get purge -y --auto-remove \
    snapd \
    lxd-installer \
    ubuntu-pro-client \
    landscape-common \
    popularity-contest \
    motd-news-config \
    plymouth \
    plymouth-theme-ubuntu-text 2>/dev/null || true

  sudo rm -rf /var/cache/snapd /root/snap /home/ubuntu/snap
  sudo apt-mark hold snapd lxd-installer 2>/dev/null || true

  # Disable marketing & telemetry timers
  sudo systemctl disable --now apt-news.service esm-cache.service motd-news.timer 2>/dev/null || true
}

install_base_essentials() {
  echo "==> Updating package repository and installing essentials..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confold' upgrade -y
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    pciutils \
    qemu-guest-agent \
    linux-generic

  sudo systemctl enable qemu-guest-agent
}

main() {
  strip_documentation_paths
  purge_distro_bloat
  install_base_essentials
  echo "==> 00-base-strip: Complete."
}

main "$@"
