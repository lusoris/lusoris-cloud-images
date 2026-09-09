---
name: prep-release
description: Validate repository readiness, manifests, and quality gates prior to publishing a release.
---

# Prepare Release Checklist

Execute this checklist before merging a release pull request or cutting a new tag.

## Pre-Release Verification
1. **Manifest Integrity**:
   Verify that `versions.json` is valid JSON and conforms to the expected schema:
   ```bash
   pytest tests/test_config.py::TestConfigIntegrity::test_versions_json_schema
   ```

2. **Quality Gates Clean**:
   Ensure all local gates pass without warnings:
   ```bash
   make lint
   make test
   ```

3. **Packer Validation Across Flavors**:
   ```bash
   cd packer && packer init . && packer validate . && cd ..
   ```

4. **Documentation Freshness**:
   Verify strict MkDocs build:
   ```bash
   mkdocs build --strict
   ```

5. **Release Please Status**:
   Check open release PR created by the Release Please action:
   ```bash
   gh pr list --label "autorelease: pending"
   ```
