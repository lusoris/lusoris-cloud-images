"""Automated verification suite for lusoris-cloud-images.

Tests configuration integrity, provisioner script standards, single source of truth (SSOT),
generational hardware flavors, and Packer validity on Ubuntu 26.04.
Adheres to NASA/JPL Power of 10: short functions, checked assertions.
"""

from pathlib import Path
import json
import jsonschema
import re
import subprocess

REPO_ROOT = Path(__file__).resolve().parent.parent
PACKER_DIR = REPO_ROOT / "packer"
PROVISIONERS_DIR = PACKER_DIR / "provisioners"
SCHEMA_PATH = REPO_ROOT / "versions.schema.json"

EXPECTED_FLAVORS = [
    "base-generic",
    "base-intel",
    "base-amd",
    "base-nvidia-legacy",
    "base-nvidia-mainstream",
    "base-nvidia-modern",
    "base-nvidia-bleeding",
    "base-nvidia-datacenter",
    "docker-generic",
    "docker-intel",
    "docker-amd",
    "docker-nvidia",
    "docker-nvidia-modern",
    "docker-nvidia-bleeding",
    "podman-generic",
    "k8s-node-generic",
    "k8s-node-cilium",
    "k8s-node-calico",
    "k8s-node-flannel",
    "k8s-node-intel",
    "k8s-node-amd",
    "k8s-node-nvidia",
    "k8s-node-nvidia-modern",
    "k8s-node-nvidia-bleeding",
    "ai-infer-generic",
    "ai-infer-intel",
    "ai-infer-amd",
    "ai-infer-nvidia",
    "ai-infer-nvidia-modern",
    "ai-infer-nvidia-bleeding",
    "k3s-agent-generic",
    "k3s-agent-intel",
    "k3s-agent-amd",
    "k3s-agent-nvidia",
    "k3s-server-generic",
    "cloudnative-generic",
    "cloudnative-k8s",
    "cloudnative-storage",
    "cloudnative-pg",
]



class TestConfigIntegrity:
    def test_core_files_exist(self) -> None:
        """Verify all core configuration, governance, and manifest files exist."""
        required_files = [
            PACKER_DIR / "versions.pkr.hcl",
            PACKER_DIR / "variables.pkr.hcl",
            PACKER_DIR / "sources.pkr.hcl",
            PACKER_DIR / "builds.pkr.hcl",
            PACKER_DIR / "http" / "user-data",
            PACKER_DIR / "http" / "meta-data",
            REPO_ROOT / "versions.json",
            SCHEMA_PATH,
            REPO_ROOT / "Makefile",
            REPO_ROOT / "AGENTS.md",
            REPO_ROOT / "CLAUDE.md",
            REPO_ROOT / "README.md",
            REPO_ROOT / "FLAVORS.md",
            REPO_ROOT / "VERSION",
            REPO_ROOT / "SECURITY.md",
            REPO_ROOT / "CONTRIBUTING.md",
            REPO_ROOT / "CODE_OF_CONDUCT.md",
            REPO_ROOT / "GOVERNANCE.md",
            REPO_ROOT / "SUPPORT.md",
            REPO_ROOT / "MAINTAINERS.md",
            REPO_ROOT / "CHANGELOG.md",
            REPO_ROOT / "mkdocs.yml",
            REPO_ROOT / ".pre-commit-config.yaml",
            REPO_ROOT / ".yamllint.yml",
            REPO_ROOT / ".gitleaks.toml",
            REPO_ROOT / ".markdownlint.json",
            REPO_ROOT / ".codespellrc",
            REPO_ROOT / "release-please-config.json",
            REPO_ROOT / ".release-please-manifest.json",
            REPO_ROOT / "renovate.json",
            REPO_ROOT / ".github" / "workflows" / "ci.yml",
            REPO_ROOT / ".github" / "workflows" / "required-aggregator.yml",
            REPO_ROOT / ".github" / "workflows" / "pages.yml",
            REPO_ROOT / ".github" / "workflows" / "release-matrix.yml",
            REPO_ROOT / ".github" / "workflows" / "release-please.yml",
            REPO_ROOT / ".github" / "workflows" / "scorecard.yml",
            REPO_ROOT / ".github" / "workflows" / "security-scans.yml",
            REPO_ROOT / ".github" / "workflows" / "supply-chain.yml",
        ]
        for file_path in required_files:
            assert file_path.exists(), f"Missing required file: {file_path}"
            assert file_path.stat().st_size > 0, f"File is empty: {file_path}"

    def test_versions_json_schema(self) -> None:
        """Verify versions.json conforms to schema and maintains semantic invariants."""
        manifest_path = REPO_ROOT / "versions.json"
        assert manifest_path.exists(), "versions.json does not exist"
        assert SCHEMA_PATH.exists(), "versions.schema.json does not exist"

        data = json.loads(manifest_path.read_text(encoding="utf-8"))
        schema = json.loads(SCHEMA_PATH.read_text(encoding="utf-8"))

        # Strict JSON schema validation
        jsonschema.validate(instance=data, schema=schema)

        # Semantic distribution validations
        assert data["distro"]["name"] == "ubuntu"
        assert re.match(r"^[a-z]+$", data["distro"]["release"])
        assert re.match(r"^\d{2}\.\d{2}$", data["distro"]["version"])

        # Semantic runtime & Kubernetes validations
        assert re.match(r"^\d+\.\d+\.\d+", data["kubernetes"]["version"])
        assert re.match(r"^\d+\.\d+$", data["kubernetes"]["major_minor"])
        assert re.match(r"^\d+\.\d+", data["runtimes"]["containerd"])
        assert re.match(r"^\d+\.\d+", data["runtimes"]["docker_ce"])

        # Driver invariants
        nvidia = data["drivers"]["nvidia"]
        assert all(isinstance(v, str) and len(v) > 0 for v in nvidia.values())
        amd = data["drivers"]["amd"]
        assert all(isinstance(v, str) and len(v) > 0 for v in amd.values())
        intel = data["drivers"]["intel"]
        assert all(isinstance(v, str) and len(v) > 0 for v in intel.values())

        # Pre-cached cluster images
        k8s_images = data["kubernetes"]["images"]
        for key in ("cilium", "calico_cni", "flannel", "kube_vip"):
            assert key in k8s_images and len(k8s_images[key]) > 0

    def test_provisioners_executable_and_strict(self) -> None:
        """Verify all provisioners are executable and enforce bash strict mode."""
        scripts = list(PROVISIONERS_DIR.glob("*.sh"))
        assert len(scripts) >= 17, f"Expected at least 17 provisioners, found {len(scripts)}"

        for script in scripts:
            assert script.stat().st_mode & 0o111, f"Script is not executable: {script.name}"
            content = script.read_text(encoding="utf-8")
            assert content.startswith("#!/usr/bin/env bash"), (
                f"Missing shebang in {script.name}"
            )
            assert "set -euo pipefail" in content, (
                f"Missing strict mode 'set -euo pipefail' in {script.name}"
            )

    def test_provisioners_power_of_ten_function_length(self) -> None:
        """Verify all functions in shell scripts adhere to NASA/JPL rule: <= 60 lines."""
        scripts = list(PROVISIONERS_DIR.glob("*.sh"))
        func_start_pattern = re.compile(r"^[a-zA-Z0-9_-]+\(\)\s*\{")

        for script in scripts:
            lines = script.read_text(encoding="utf-8").splitlines()
            current_func = None
            func_line_count = 0

            for line in lines:
                if current_func is None:
                    if func_start_pattern.match(line):
                        current_func = line.split("(")[0].strip()
                        func_line_count = 1
                else:
                    func_line_count += 1
                    if line.strip() == "}":
                        assert func_line_count <= 60, (
                            f"Function '{current_func}' in {script.name} exceeds 60 lines "
                            f"({func_line_count} lines). Violates NASA/JPL Power of 10."
                        )
                        current_func = None

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

    def test_no_private_ips_or_user_paths(self) -> None:
        """Verify no private RFC 1918 IPs or developer home paths leak into configs."""
        prohibited_user_paths = re.compile(r"/home/(?!(ubuntu|username)\b)[\w-]+")
        prohibited_ip_patterns = re.compile(
            r"\b(10\.\d{1,3}\.\d{1,3}\.\d{1,3}|192\.168\.\d{1,3}\.\d{1,3}|172\.(1[6-9]|2\d|3[01])\.\d{1,3}\.\d{1,3})\b"
        )
        ignored_paths = {".git", ".pytest_cache", "__pycache__", "tests"}

        for path in REPO_ROOT.rglob("*"):
            if path.is_file() and not any(part in ignored_paths for part in path.parts):
                try:
                    content = path.read_text(encoding="utf-8", errors="ignore")
                except Exception:
                    continue

                # Check developer home paths across all files
                assert not prohibited_user_paths.search(content), (
                    f"Found prohibited user home path in {path.relative_to(REPO_ROOT)}"
                )

                # Check RFC 1918 IPs in non-documentation files
                if not (path.suffix == ".md" or "docs" in path.parts):
                    assert not prohibited_ip_patterns.search(content), (
                        f"Found prohibited private RFC 1918 IP in {path.relative_to(REPO_ROOT)}"
                    )

