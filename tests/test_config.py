"""Automated verification suite for lusoris-cloud-images.

Tests configuration integrity, provisioner script standards, and Packer validity.
Adheres to NASA/JPL Power of 10: short functions, checked assertions.
"""

from pathlib import Path
import subprocess

REPO_ROOT = Path(__file__).resolve().parent.parent
PACKER_DIR = REPO_ROOT / "packer"
PROVISIONERS_DIR = PACKER_DIR / "provisioners"

EXPECTED_FLAVORS = [
    "base-generic",
    "base-intel",
    "base-amd",
    "base-nvidia",
    "k8s-node-generic",
    "k8s-node-intel",
    "k8s-node-amd",
    "k8s-node-nvidia",
]


class TestConfigIntegrity:
    def test_core_files_exist(self) -> None:
        """Verify all core configuration files exist in the repository."""
        required_files = [
            PACKER_DIR / "versions.pkr.hcl",
            PACKER_DIR / "variables.pkr.hcl",
            PACKER_DIR / "sources.pkr.hcl",
            PACKER_DIR / "builds.pkr.hcl",
            PACKER_DIR / "http" / "user-data",
            PACKER_DIR / "http" / "meta-data",
            REPO_ROOT / "Makefile",
            REPO_ROOT / "AGENTS.md",
            REPO_ROOT / "README.md",
            REPO_ROOT / "ONBOARDING.md",
            REPO_ROOT / "VERSION",
        ]
        for file_path in required_files:
            assert file_path.exists(), f"Missing required file: {file_path}"
            assert file_path.stat().st_size > 0, f"File is empty: {file_path}"

    def test_provisioners_executable_and_strict(self) -> None:
        """Verify all provisioners are executable and enforce bash strict mode."""
        scripts = list(PROVISIONERS_DIR.glob("*.sh"))
        assert len(scripts) >= 8, f"Expected at least 8 provisioners, found {len(scripts)}"

        for script in scripts:
            assert script.stat().st_mode & 0o111, f"Script is not executable: {script.name}"
            content = script.read_text(encoding="utf-8")
            assert content.startswith("#!/usr/bin/env bash"), (
                f"Missing shebang in {script.name}"
            )
            assert "set -euo pipefail" in content, (
                f"Missing strict mode 'set -euo pipefail' in {script.name}"
            )

    def test_all_flavors_defined_in_builds(self) -> None:
        """Verify all architectural flavors are defined in builds.pkr.hcl."""
        builds_content = (PACKER_DIR / "builds.pkr.hcl").read_text(encoding="utf-8")
        for flavor in EXPECTED_FLAVORS:
            assert f'name    = "{flavor}"' in builds_content, (
                f"Flavor {flavor} missing from builds.pkr.hcl"
            )

    def test_packer_validate(self) -> None:
        """Verify Packer configuration passes validation."""
        result = subprocess.run(
            ["packer", "validate", "."],
            cwd=str(PACKER_DIR),
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 0, f"Packer validation failed: {result.stderr}"

    def test_shellcheck_clean(self) -> None:
        """Verify ShellCheck runs clean with zero warnings on all provisioners."""
        scripts = [str(p) for p in PROVISIONERS_DIR.glob("*.sh")]
        result = subprocess.run(
            ["shellcheck", *scripts],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 0, f"ShellCheck detected issues: {result.stdout}"
