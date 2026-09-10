"""Automated verification suite for documentation and architectural records.

Validates MkDocs navigation tree completeness, ADR Nygard format adherence,
ADR index synchrony, absence of placeholder emails, and CHANGELOG structure.
Complies with NASA/JPL Power of 10: short functions (<= 60 lines), checked assertions.
"""

from pathlib import Path
import re
import yaml

REPO_ROOT = Path(__file__).resolve().parent.parent
DOCS_DIR = REPO_ROOT / "docs"
MKDOCS_CONFIG = REPO_ROOT / "mkdocs.yml"
ADR_DIR = DOCS_DIR / "adr"
CHANGELOG_PATH = REPO_ROOT / "CHANGELOG.md"


class MkDocsLoader(yaml.SafeLoader):
    """Custom YAML loader ignoring python-specific mkdocs tags."""
    pass

MkDocsLoader.add_multi_constructor("tag:yaml.org,2002:python/", lambda loader, suffix, node: None)


def extract_nav_paths(node):
    """Recursively collect all target documentation file paths from mkdocs nav."""
    paths = []
    if isinstance(node, dict):
        for val in node.values():
            paths.extend(extract_nav_paths(val))
    elif isinstance(node, list):
        for item in node:
            paths.extend(extract_nav_paths(item))
    elif isinstance(node, str) and node.endswith(".md"):
        paths.append(node)
    return paths


class TestDocsIntegrity:
    def test_mkdocs_nav_files_exist(self) -> None:
        """Verify every markdown file declared in mkdocs.yml nav exists on disk."""
        assert MKDOCS_CONFIG.exists(), "mkdocs.yml is missing"
        config = yaml.load(MKDOCS_CONFIG.read_text(encoding="utf-8"), Loader=MkDocsLoader)
        nav = config.get("nav", [])
        nav_files = extract_nav_paths(nav)

        assert len(nav_files) >= 15, f"Expected >= 15 nav items, found {len(nav_files)}"
        for rel_file in nav_files:
            file_path = DOCS_DIR / rel_file
            assert file_path.exists(), f"File in mkdocs.yml nav does not exist: {file_path}"
            assert file_path.stat().st_size > 0, f"File in mkdocs.yml nav is empty: {file_path}"

    def test_adr_nygard_format(self) -> None:
        """Verify all ADR files adhere to Nygard structure (Status, Context, Decision, Consequences)."""
        adr_files = sorted(ADR_DIR.glob("0*.md"))
        assert len(adr_files) >= 5, f"Expected at least 5 ADRs, found {len(adr_files)}"

        required_sections = ["## Status", "## Context", "## Decision", "## Consequences"]
        for adr in adr_files:
            content = adr.read_text(encoding="utf-8")
            for sec in required_sections:
                assert sec in content, f"ADR {adr.name} is missing mandatory section '{sec}'"

    def test_adr_index_synchrony(self) -> None:
        """Verify all ADR files are cataloged in docs/adr/README.md."""
        readme = ADR_DIR / "README.md"
        assert readme.exists(), "docs/adr/README.md index is missing"
        index_content = readme.read_text(encoding="utf-8")

        for adr in ADR_DIR.glob("0*.md"):
            assert adr.name in index_content, (
                f"ADR {adr.name} is missing from the table in docs/adr/README.md"
            )

    def test_no_placeholder_emails(self) -> None:
        """Verify documentation contains no fake or placeholder contact email addresses."""
        placeholder_pattern = re.compile(
            r"\b[A-Za-z0-9._%+-]+@(example\.com|example\.org|yourdomain\.com|test\.com|domain\.com)\b",
            re.IGNORECASE,
        )
        for md_file in REPO_ROOT.rglob("*.md"):
            if ".workingdir2" in md_file.parts or ".pytest_cache" in md_file.parts:
                continue
            content = md_file.read_text(encoding="utf-8", errors="ignore")
            match = placeholder_pattern.search(content)
            assert not match, (
                f"Prohibited placeholder email '{match.group(0)}' found in {md_file.relative_to(REPO_ROOT)}. "
                f"Use GitHub native surfaces exclusively."
            )

    def test_changelog_structure(self) -> None:
        """Verify CHANGELOG.md exists and adheres to Keep a Changelog format."""
        assert CHANGELOG_PATH.exists(), "CHANGELOG.md is missing"
        content = CHANGELOG_PATH.read_text(encoding="utf-8")
        assert "## [Unreleased]" in content, "Missing '## [Unreleased]' section in CHANGELOG.md"
        assert any(sec in content for sec in ["### Added", "### Changed", "### Fixed"]), (
            "CHANGELOG.md missing standard category sections"
        )
