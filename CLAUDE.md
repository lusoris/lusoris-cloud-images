<!-- markdownlint-disable MD013 -->
# Claude Code guide — lusoris-cloud-images

> Project guide for Claude Code and autonomous engineering agents. For cross-tool conventions read [AGENTS.md](AGENTS.md) first; this file extends it.

## What this is

An enterprise-grade, hardened, hardware-accelerated OS image forge producing minimal cloud images (`.qcow2`, `.raw`, `.vmdk`, Proxmox/Unraid/VMware templates).

## How to build / test / gate

```bash
make fmt-check                  # Verify Packer HCL formatting
make lint                       # Run packer validate, shellcheck, and yamllint
make test                       # Run automated Pytest verification suite
pre-commit run --all-files      # Run gitleaks, shfmt, shellcheck, codespell, markdownlint

make build-base-generic         # Build base-generic image via local QEMU/KVM
make build-docker-generic       # Build docker-generic image
make build-k8s-generic          # Build k8s-node-generic image
```

## Architectural Invariants (Do Not Break)

1. **Single Source of Truth (`versions.json`)**:
   Never hardcode versions, container image tags, or driver branches in Packer templates or shell provisioners. All versions must originate from `versions.json` and pass via environment variables.
2. **Trunk-Based PR Flow**:
   Never commit directly to `main`. Always create a branch (`feat/*`, `fix/*`, `chore/*`), run all local gates, push, and open a PR with `gh pr create`.
3. **NASA/JPL Power of 10 Compliance**:
   All shell provisioner functions must be <= 60 lines, enforce `set -euo pipefail`, check return codes, and pass ShellCheck with zero warnings.
4. **Zero Base Bloat & Telemetry**:
   Never reintroduce snapd, telemetry daemons, or unneeded docs/locales.
5. **No Leaked Subnets or Paths**:
   Never hardcode RFC 1918 private subnets (`10.x`, `192.168.x`, `172.16-31.x`) or developer home directories (`/home/*`). Use documentation addresses (`192.0.2.x`, `example.com`).

## Release & Changelog Conventions

- Use Conventional Commits (`feat:`, `fix:`, `chore:`, `refactor:`, `docs:`).
- Releases are automated via Release Please (`release-please.yml`).
