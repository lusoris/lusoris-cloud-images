#!/usr/bin/env bash
# 99-cleanup.sh — Template sanitization, log truncation, and thin-provision trimming
# Ensures clean first boot, regenerated machine-id, and minimal disk footprint.
set -euo pipefail

clean_cloud_init() {
  echo "==> Sanitizing cloud-init state..."
  sudo cloud-init clean --logs --seed || true
  # Drop cloud-init datasources not needed on bare-metal or local hypervisors
  echo 'datasource_list: [ NoCloud, ConfigDrive, None ]' | sudo tee /etc/cloud/cloud.cfg.d/99_datasource.cfg
}

clean_apt_cache() {
  echo "==> Cleaning apt caches and index files..."
  sudo apt-get autoremove --purge -y || true
  sudo apt-get clean
  sudo rm -rf /var/lib/apt/lists/*
}

clean_machine_identities() {
  echo "==> Resetting machine-id and regenerating on next boot..."
  sudo truncate -s 0 /etc/machine-id
  sudo rm -f /var/lib/dbus/machine-id
  sudo ln -sf /etc/machine-id /var/lib/dbus/machine-id

  echo "==> Removing host SSH keys for unique regeneration..."
  sudo rm -f /etc/ssh/ssh_host_*
}

clean_logs_and_histories() {
  echo "==> Truncating log files and clearing bash histories..."
  sudo rm -f /root/.bash_history /home/ubuntu/.bash_history
  sudo journalctl --rotate 2>/dev/null || true
  sudo journalctl --vacuum-time=1s 2>/dev/null || true
  sudo rm -rf /var/log/journal/*

  sudo find /var/log -type f -exec truncate -s 0 {} \; 2>/dev/null || true
  sudo rm -rf /tmp/* /var/tmp/*
}

zero_free_space() {
  echo "==> Running fstrim to reclaim thin-provisioned storage..."
  sudo fstrim -av 2>/dev/null || true
}

main() {
  clean_cloud_init
  clean_apt_cache
  clean_machine_identities
  clean_logs_and_histories
  zero_free_space
  echo "==> 99-cleanup: Template cleanup complete."
}

main "$@"
