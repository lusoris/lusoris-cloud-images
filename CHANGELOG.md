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

## [0.1.0] - 2026-09-09

### Added
- Initial repository bootstrap for lusoris-cloud-images.
- Standalone QEMU and Proxmox Packer HCL2 builders.
- Hardware-accelerated GPU stacks: Intel Arc/iGPU, AMD Radeon, NVIDIA Container Toolkit.
- Kubernetes node flavors with pre-baked containerd 2.x, kubelet, and daemonset caching.
- Automated verification suite and linters.
