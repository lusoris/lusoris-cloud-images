#!/usr/bin/env bash
# 10-network-ptb.sh — Authoritative PTB NTS time policy configuration
# Uses Physikalisch-Technische Bundesanstalt (PTB) NTS servers via chrony.
set -euo pipefail

install_chrony() {
  echo "==> Installing chrony..."
  sudo apt-get update
  sudo DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends chrony
}

configure_ptb_sources() {
  echo "==> Writing PTB NTS sources..."
  # Purge default Ubuntu sources
  sudo find /etc/chrony/sources.d -maxdepth 1 -type f -name 'ubuntu*.sources' -delete 2>/dev/null || true

  # Disable DHCP NTP source overriding
  if [ -f /etc/chrony/chrony.conf ]; then
    sudo sed -Ei 's|^[[:space:]]*sourcedir[[:space:]]+/run/chrony-dhcp[[:space:]]*$|# sourcedir /run/chrony-dhcp  # Disabled: enforce authoritative NTS sources only.|' /etc/chrony/chrony.conf
  fi

  # Write authoritative PTB sources with Network Time Security (NTS)
  cat <<'EOF' | sudo tee /etc/chrony/sources.d/ptb.sources
# Authoritative PTB NTS Time Sources (Physikalisch-Technische Bundesanstalt)
server ptbtime1.ptb.de iburst nts
server ptbtime2.ptb.de iburst nts
server ptbtime3.ptb.de iburst nts
server ptbtime4.ptb.de iburst nts
EOF

  cat <<'EOF' | sudo tee /etc/chrony/conf.d/ptb-policy.conf
# PTB NTS Security & Stepping Policy
makestep 1.0 3
rtconutc
minsources 2
authselectmode require
EOF
}

verify_and_enable_chrony() {
  echo "==> Verifying and starting chrony service..."
  sudo chronyd -p >/dev/null
  sudo systemctl enable chrony.service
  sudo systemctl restart chrony.service
}

main() {
  install_chrony
  configure_ptb_sources
  verify_and_enable_chrony
  echo "==> 10-network-ptb: Complete."
}

main "$@"
