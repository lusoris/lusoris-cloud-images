<!-- markdownlint-disable MD013 -->
# Claude Code guide — lusoris-cloud-images

> Tool entry point for Claude Code and autonomous engineering agents.
>
> The canonical repository instructions are [`AGENTS.md`](AGENTS.md) and
> [`docs/principles.md`](docs/principles.md). Read those files before making changes.
>
> This file intentionally does not duplicate their full rules to prevent authority drift.

## Quick verification commands

```bash
make fmt-check                  # Verify Packer HCL formatting
make lint                       # Run packer validate, shellcheck, and yamllint
make test                       # Run automated Pytest verification suite
pre-commit run --all-files      # Run gitleaks, shfmt, shellcheck, codespell, markdownlint

# Build targets
make build-base-generic         # Build base-generic image via local QEMU/KVM
make build-docker-generic       # Build docker-generic image
make build-k8s-generic          # Build k8s-node-generic image
make build-ai-infer-generic     # Build CPU inference image
```

## Architectural Invariants (Do Not Break)

1. **Single Source of Truth (`versions.json`)**: All upstream versions, tags, and URLs live exclusively in [`versions.json`](versions.json).
2. **Trunk-Based PR Flow**: Never commit directly to `main`. Create short-lived branches (`feat/*`, `fix/*`, `chore/*`) and open PRs with `gh pr create`.
3. **NASA/JPL Power of 10**: Shell functions $\le$ 60 lines, bounded loops, checked returns, `set -euo pipefail`.
4. **Privacy & Zero-Leak**: Zero RFC 1918 private IPs (`10.x`, `192.168.x`, `172.16-31.x`) and zero workstation path leaks (`/home/*`).
5. **Docs Synchrony**: Every user-discoverable addition or change must ship documentation under `docs/` in the same commit.

## Interaction Style — Ask Only on Real Forks

- Act on unambiguous work directly without stopping or narrating between steps.
- When an operation genuinely branches on a call only the operator can make, use structured popup questions with concrete options and recommended choices.
