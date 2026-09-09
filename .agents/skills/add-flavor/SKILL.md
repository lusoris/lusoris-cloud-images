---
name: add-flavor
description: Add a new image flavor (hardware or workload tier) to lusoris-cloud-images with full SSOT, test, and documentation synchrony.
---

# Add Flavor Skill

Follow this end-to-end workflow when creating a new OS image flavor in `lusoris-cloud-images`.

## Invariants to Preserve
1. **Single Source of Truth**: All versions, container tags, and driver branches must be defined in `versions.json`. Never hardcode strings in templates or provisioners.
2. **NASA/JPL Power of 10**: Any new shell provisioner scripts must enforce `set -euo pipefail`, have functions $\le$ 60 lines, check all return codes, and pass ShellCheck.
3. **Docs Synchrony**: The new flavor must be documented in `docs/` and `README.md` in the same commit.

## Procedure

### 1. Update Version Manifest
If the flavor introduces new software versions, add them to `versions.json`:
```json
{
  "drivers": {
    ...
  }
}
```

### 2. Define Build Target in Packer
In `packer/builds.pkr.hcl`, add the new build target block:
```hcl
build {
  name = "flavor-name"
  sources = ["source.qemu.image"]
  ...
}
```

### 3. Add or Configure Provisioners
If new provisioning logic is needed, create or update `packer/provisioners/NN-flavor-name.sh`:
- Include strict header:
  ```bash
  #!/usr/bin/env bash
  set -euo pipefail
  ```
- Make script executable: `chmod +x packer/provisioners/NN-flavor-name.sh`.
- Validate with ShellCheck: `shellcheck packer/provisioners/NN-flavor-name.sh`.

### 4. Update Verification Suite
Add the flavor name to `EXPECTED_FLAVORS` in `tests/test_config.py`.

### 5. Update Makefile
Add build targets in `Makefile`:
```makefile
build-flavor-name: ## Build flavor-name image via local QEMU/KVM
	@cd packer && packer init . && packer build -only="flavor-name.qemu.image" .
```

### 6. Update Documentation
- Add the flavor row to `docs/flavors/matrix.md` and `README.md`.
- Add/update the relevant topic page under `docs/flavors/` or `docs/hardware/`.

### 7. Verify
```bash
make fmt-check
make lint
make test
```
