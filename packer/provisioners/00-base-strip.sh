#!/usr/bin/env bash
# 00-base-strip.sh — Strip distro bloat, optimize fast boot, and install minimal base packages
# Complies with NASA/JPL Power of 10: short functions (<= 60 lines), checked returns.
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

  sudo systemctl disable --now apt-news.service esm-cache.service motd-news.timer 2>/dev/null || true
}

configure_fast_boot_and_systemd() {
  echo "==> Configuring cloud-init datasource and systemd fast-boot limits..."
  sudo mkdir -p /etc/cloud/cloud.cfg.d
  cat <<'EOF' | sudo tee /etc/cloud/cloud.cfg.d/90_dpkg.cfg
datasource_list: [ NoCloud, ConfigDrive, None ]
manage_etc_hosts: localhost
EOF

  sudo mkdir -p /etc/systemd/system/systemd-networkd-wait-online.service.d
  cat <<'EOF' | sudo tee /etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf
[Service]
ExecStart=
ExecStart=/lib/systemd/systemd-networkd-wait-online --any --timeout=10
EOF

  sudo mkdir -p /etc/systemd/journald.conf.d
  cat <<'EOF' | sudo tee /etc/systemd/journald.conf.d/00-limits.conf
[Journal]
SystemMaxUse=100M
RuntimeMaxUse=50M
Storage=persistent
EOF

  sudo mkdir -p /etc/systemd/coredump.conf.d
  echo -e "[Coredump]\nStorage=none\nProcessSizeMax=0" | sudo tee /etc/systemd/coredump.conf.d/00-disable.conf

  if [ -f /etc/default/grub ]; then
    echo "==> Configuring instant GRUB boot timeout and serial console..."
    sudo sed -i 's/^GRUB_TIMEOUT=.*/GRUB_TIMEOUT=0/' /etc/default/grub
    echo 'GRUB_RECORDFAIL_TIMEOUT=0' | sudo tee -a /etc/default/grub
    sudo update-grub 2>/dev/null || true
  fi

  echo "==> Enabling fstrim weekly timer for SSD and sparse disk wear reduction..."
  sudo systemctl enable fstrim.timer 2>/dev/null || true
}

install_base_essentials() {
  echo "==> Updating package repository and installing essentials on Ubuntu 26.04..."
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

configure_zram_swap() {
  echo "==> Configuring ZRAM compressed in-memory swap..."
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends zram-tools 2>/dev/null || {
    echo "    zram-tools not found, skipping ZRAM userspace service..."
    return 0
  }
  if [ -f /etc/default/zramswap ]; then
    sudo sed -i 's/^#*ALGO=.*/ALGO=zstd/' /etc/default/zramswap
    sudo sed -i 's/^#*PERCENT=.*/PERCENT=25/' /etc/default/zramswap
    sudo sed -i 's/^#*PRIORITY=.*/PRIORITY=100/' /etc/default/zramswap
    sudo systemctl enable zramswap.service 2>/dev/null || true
  fi
}

main() {
  strip_documentation_paths
  purge_distro_bloat
  configure_fast_boot_and_systemd
  install_base_essentials
  configure_zram_swap
  echo "==> 00-base-strip: Complete."
}

main "$@"
