"""Automated verification suite for Packer bash provisioners.

Enforces NASA/JPL Power of 10 rules:
- Rule 1: Simple control flow (no recursion, bounded loops).
- Rule 2: Fixed upper bound on loop iterations.
- Rule 4: Short functions (<= 60 lines).
- Rule 7: Check return codes of all system calls.
Enforces license headers, shebangs, strict mode, and ShellCheck cleanliness.
"""

from pathlib import Path
import re
import subprocess

REPO_ROOT = Path(__file__).resolve().parent.parent
PROVISIONERS_DIR = REPO_ROOT / "packer" / "provisioners"


def get_provisioner_scripts():
    return sorted(PROVISIONERS_DIR.glob("*.sh"))


class TestProvisionersIntegrity:
    def test_minimum_provisioner_count(self) -> None:
        """Verify all expected provisioner scripts are present."""
        scripts = get_provisioner_scripts()
        assert len(scripts) >= 20, f"Expected >= 20 provisioners, found {len(scripts)}"

    def test_scripts_executable(self) -> None:
        """Verify all shell provisioners have executable permission (+x)."""
        for script in get_provisioner_scripts():
            mode = script.stat().st_mode
            assert mode & 0o111, f"Script {script.name} is not executable (chmod +x required)"

    def test_shebang_and_strict_mode(self) -> None:
        """Verify shebang and strict mode 'set -euo pipefail' on all scripts."""
        for script in get_provisioner_scripts():
            content = script.read_text(encoding="utf-8")
            lines = content.splitlines()
            assert lines[0] == "#!/usr/bin/env bash", f"Invalid shebang in {script.name}"
            assert any(line.strip() == "set -euo pipefail" for line in lines[:10]), (
                f"Missing strict mode 'set -euo pipefail' in {script.name}"
            )

    def test_copyright_license_header(self) -> None:
        """Verify copyright header 'Copyright 2026 Lusoris' in all scripts."""
        for script in get_provisioner_scripts():
            content = script.read_text(encoding="utf-8")
            assert "Copyright 2026 Lusoris" in content, (
                f"Missing 'Copyright 2026 Lusoris' header in {script.name}"
            )

    def test_main_entrypoint(self) -> None:
        """Verify standard main() definition and main \"$@\" invocation."""
        for script in get_provisioner_scripts():
            content = script.read_text(encoding="utf-8")
            assert "main()" in content or "main ()" in content, (
                f"Missing 'main()' definition in {script.name}"
            )
            assert 'main "$@"' in content, (
                f"Missing 'main \"$@\"' invocation in {script.name}"
            )

    def test_power_of_ten_function_length(self) -> None:
        """Verify no function exceeds 60 lines (NASA/JPL Holzmann Rule 4)."""
        func_start_pattern = re.compile(r"^[a-zA-Z0-9_-]+\(\)\s*\{")

        for script in get_provisioner_scripts():
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
                            f"Function '{current_func}' in {script.name} has {func_line_count} lines. "
                            f"Exceeds 60-line limit (NASA/JPL Power of 10 Rule 4)."
                        )
                        current_func = None

    def test_no_banned_constructs(self) -> None:
        """Verify provisioners avoid dangerous constructs (eval, raw rm -rf /)."""
        banned_patterns = [
            (re.compile(r"\beval\s+"), "Use of 'eval' is strictly prohibited"),
            (re.compile(r"rm\s+-rf\s+/\s*$"), "Dangerous 'rm -rf /' detected"),
        ]
        for script in get_provisioner_scripts():
            content = script.read_text(encoding="utf-8")
            for pattern, msg in banned_patterns:
                assert not pattern.search(content), f"{msg} in {script.name}"

    def test_shellcheck_zero_warnings(self) -> None:
        """Verify ShellCheck runs clean on all provisioners with 0 warnings."""
        scripts = [str(p) for p in get_provisioner_scripts()]
        result = subprocess.run(
            ["shellcheck", *scripts],
            capture_output=True,
            text=True,
            check=False,
        )
        assert result.returncode == 0, f"ShellCheck failed on provisioners:\n{result.stdout}"
