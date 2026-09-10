# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- CloudNative immutable container host and Kubernetes node flavors (`cloudnative-generic`, `cloudnative-k8s`).
- CNCF Storage appliance (`cloudnative-storage`) with NVMe-oF TCP, OpenZFS 2.3, iSCSI, and multipath support.
- CloudNativePG database host flavor (`cloudnative-pg`) with strict memory overcommit and checkpoint dirty-ratio tuning.
- K3s Edge Fleet flavors (`k3s-agent-generic`, `k3s-agent-intel`, `k3s-agent-amd`, `k3s-agent-nvidia`, `k3s-server-generic`).
- Hypervisor performance engine: weekly `fstrim.timer`, ZRAM swap guard, VirtIO `mq-deadline` scheduler, fast NoCloud cloud-init discovery.
- Single Source of Truth `versions.schema.json` schema validation for automated version bump decoupling.
- Dedicated segmented flavor catalog in `FLAVORS.md` partitioning 39 flavors across 6 workload tiers.
- Streamlined `README.md` with multi-tier badge rows, architecture diagram, and workload summary table.
- Interactive tabbed flavor explorer in `docs/flavors/matrix.md`.
- Comprehensive modular test coverage suite (48 tests across 8 modules: manifest SSOT, provisioner static analysis, flavor matrix, cloud-init seed data, documentation/ADR integrity, security/privacy invariants, Packer templates, and repository governance).
- Tier 7: Specialized Homelab Appliances (5 new flavors: `appliance-vision-nvr`, `appliance-gateway-dns`, `appliance-media-server`, `appliance-ci-runner`, `appliance-game-server`) addressing r/homelab and Steam survey hardware patterns.
- Comprehensive documentation bug hunt: corrected Tier 3 Kubernetes flavor count from 10 to 9, fixed 44-flavor count synchrony across matrix.md, and updated provisioner log messages in `61-cloudnative-immutable.sh`.
- Visual architecture overhaul: integrated 10 low-cognitive-load, theme-resilient Mermaid diagrams across landing pages, flavor matrix, Kubernetes node stack, AI inference pipeline, NTS multi-peer time architecture, direct disk streaming, CLI/MCP framing sequence, and multi-architecture boot hierarchy.
- Automated Mermaid syntax and diagram type verification suite in `tests/test_docs.py`.

## [0.1.0] - 2026-09-09

### Added
- Initial repository bootstrap for lusoris-cloud-images.
- Standalone QEMU and Proxmox Packer HCL2 builders.
- Hardware-accelerated GPU stacks: Intel Arc/iGPU, AMD Radeon, NVIDIA Container Toolkit.
- Kubernetes node flavors with pre-baked containerd 2.x, kubelet, and daemonset caching.
- Automated verification suite and linters.
