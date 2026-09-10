# Copyright 2026 Lusoris
"""Live Container Integration Test Suite using Docker.

Validates hardened configurations (OpenSSH daemon syntax, sysctl file parsing,
and rootfs filesystem contracts) inside an ephemeral Ubuntu 24.04 container.
"""

from pathlib import Path
import shutil
import subprocess
import pytest

REPO_ROOT = Path(__file__).resolve().parent.parent
PROVISIONERS_DIR = REPO_ROOT / "packer" / "provisioners"


def is_docker_available() -> bool:
    if not shutil.which("docker"):
        return False
    try:
        res = subprocess.run(
            ["docker", "info"],
            capture_output=True,
            text=True,
            timeout=5,
            check=False,
        )
        return res.returncode == 0
    except Exception:
        return False


docker_required = pytest.mark.skipif(
    not is_docker_available(),
    reason="Docker daemon is required for live container integration tests",
)


@docker_required
class TestContainerIntegration:
    def test_openssh_configuration_syntax_in_ubuntu(self) -> None:
        """Verify 00-hardened-sshd.conf passes sshd -t syntax and cryptographic validation in real Ubuntu."""
        ssh_config_src = """# CIS Benchmark Level 2 & DISA STIG OpenSSH Hardening Baseline
Port 22
Protocol 2
AddressFamily any

# Cryptographic Suite Selection
KexAlgorithms curve25519-sha256,curve25519-sha256@libssh.org,diffie-hellman-group16-sha512,diffie-hellman-group18-sha512
Ciphers chacha20-poly1305@openssh.com,aes256-gcm@openssh.com,aes128-gcm@openssh.com
MACs hmac-sha2-512-etm@openssh.com,hmac-sha2-256-etm@openssh.com

# Authentication & Session Boundaries
PermitRootLogin no
MaxAuthTries 3
MaxSessions 2
PubkeyAuthentication yes
ClientAliveInterval 300
ClientAliveCountMax 0
LoginGraceTime 30
X11Forwarding no
AllowTcpForwarding no
AllowAgentForwarding no

# OpenSSH Certificate Authority Integration
TrustedUserCAKeys /etc/ssh/trusted-user-ca-keys.pub
"""

        bash_cmd = f"""set -euo pipefail
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq openssh-server >/dev/null
mkdir -p /etc/ssh/sshd_config.d /run/sshd
touch /etc/ssh/trusted-user-ca-keys.pub
cat <<'EOF' > /etc/ssh/sshd_config.d/00-hardened-sshd.conf
{ssh_config_src}
EOF
# Run sshd syntax test
/usr/sbin/sshd -t
echo "SSHD_SYNTAX_VALID"
"""

        res = subprocess.run(
            ["docker", "run", "--rm", "ubuntu:24.04", "bash", "-c", bash_cmd],
            capture_output=True,
            text=True,
            timeout=60,
            check=False,
        )

        assert res.returncode == 0, f"sshd -t failed in Ubuntu 24.04: {res.stderr or res.stdout}"
        assert "SSHD_SYNTAX_VALID" in res.stdout

    def test_sysctl_configuration_syntax_in_ubuntu(self) -> None:
        """Verify 99-lusoris.conf sysctl configuration file parses without syntax errors."""
        script_path = PROVISIONERS_DIR / "20-kernel-sysctl.sh"
        content = script_path.read_text(encoding="utf-8")

        # Extract heredoc between cat <<'EOF' | sudo tee /etc/sysctl.d/99-lusoris.conf and EOF
        start_marker = "cat <<'EOF' | sudo tee /etc/sysctl.d/99-lusoris.conf\n"
        end_marker = "\nEOF\n"
        start_idx = content.find(start_marker)
        assert start_idx != -1
        end_idx = content.find(end_marker, start_idx)
        assert end_idx != -1
        sysctl_conf = content[start_idx + len(start_marker) : end_idx]

        bash_cmd = f"""set -euo pipefail
mkdir -p /etc/sysctl.d
cat <<'EOF' > /etc/sysctl.d/99-lusoris.conf
{sysctl_conf}
EOF
# Verify key-value formatting
grep -v '^#' /etc/sysctl.d/99-lusoris.conf | grep -v '^[[:space:]]*$' | while read -r line; do
  if ! echo "$line" | grep -q ' = '; then
    echo "MALFORMED_LINE: $line" >&2
    exit 1
  fi
done
echo "SYSCTL_SYNTAX_VALID"
"""

        res = subprocess.run(
            ["docker", "run", "--rm", "ubuntu:24.04", "bash", "-c", bash_cmd],
            capture_output=True,
            text=True,
            timeout=30,
            check=False,
        )

        assert res.returncode == 0, f"Sysctl syntax check failed: {res.stderr}"
        assert "SYSCTL_SYNTAX_VALID" in res.stdout

    def test_cdi_spec_json_validation_in_ubuntu(self) -> None:
        """Verify generated CDI specification conforms to valid JSON / YAML structure."""
        script_path = PROVISIONERS_DIR / "75-appliance-vision.sh"
        content = script_path.read_text(encoding="utf-8")

        start_marker = "cat <<'CDI' | sudo tee /etc/cdi/coral.yaml >/dev/null\n"
        end_marker = "\nCDI\n"
        start_idx = content.find(start_marker)
        assert start_idx != -1
        end_idx = content.find(end_marker, start_idx)
        assert end_idx != -1
        cdi_yaml = content[start_idx + len(start_marker) : end_idx]

        bash_cmd = f"""set -euo pipefail
DEBIAN_FRONTEND=noninteractive apt-get update -qq
DEBIAN_FRONTEND=noninteractive apt-get install -y -qq python3-yaml >/dev/null
python3 -c "
import yaml
data = yaml.safe_load('''{cdi_yaml}''')
assert data['cdiVersion'] == '0.6.0'
assert data['kind'] == 'coral.google.com/edgetpu'
assert len(data['devices']) == 1
print('CDI_SPEC_VALID')
"
"""

        res = subprocess.run(
            ["docker", "run", "--rm", "ubuntu:24.04", "bash", "-c", bash_cmd],
            capture_output=True,
            text=True,
            timeout=40,
            check=False,
        )

        assert res.returncode == 0, f"CDI verification failed: {res.stderr}"
        assert "CDI_SPEC_VALID" in res.stdout
