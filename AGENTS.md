# AGENTS.md — Agent & Contributor Directives

> Authoritative operating guide for all autonomous engineering agents and human contributors in `lusoris-cloud-images`.

---

## 🌟 TOP-PRIORITY GLOBAL RULES

1. **Single Source of Truth (`versions.json`)**:
   Never hardcode distribution URLs, Kubernetes versions, container tags, or driver branches in Packer templates or shell provisioners. All versions must originate from [`versions.json`](versions.json) and be injected via Packer environment variables.
2. **Trunk-Based PR Merge Flow**:
   Direct commits to `main` are strictly prohibited. Always create a short-lived branch (`feat/*`, `fix/*`, `chore/*`), run all local quality gates, push, and open a PR with `gh pr create`. Merges require passing the `required-checks` aggregator.
3. **Preserve Architectural Invariants**:
   Every invariant defined in Section 2 must be maintained across all modifications. If an edit risks violating an invariant, stop, verify, and resolve the invariant first.
4. **Docs & Code Synchrony**:
   Every user-discoverable change (new flavor, configuration variable, or provisioner step) must be reflected in documentation ([README.md](README.md) and [`docs/`](docs/)) in the **exact same commit**.
5. **NASA/JPL Power of 10 Compliance**:
   All shell provisioner functions must be <= 60 lines, enforce `set -euo pipefail`, check return codes, and pass ShellCheck with zero warnings.
6. **Privacy & Zero-Leak Invariant**:
   Never commit private RFC 1918 IP addresses (`10.x`, `192.168.x`, `172.16-31.x`) or local workstation home paths. Use standard documentation placeholders (`pve.example.com`, `192.0.2.x`).
7. **All Documentation in English**:
   All commit messages, code comments, documentation, and agent reports must be written in a neutral, professional English register.

---

## 1. Mission & Purpose

`lusoris-cloud-images` produces clean, hardened, production-ready cloud and bare-metal OS images optimized for virtualization (Proxmox VE, Unraid, VMware ESXi, QEMU/KVM, Public Clouds) and bare-metal servers.

Key capabilities:
- **Zero Base Bloat**: Purges `snapd`, `lxd`, Ubuntu Pro telemetry, motd news, and unneeded documentation/locales.
- **Hardware Acceleration Flavors**: Dedicated flavors for Intel Arc/Xe, AMD Mesa/ROCm, and NVIDIA generational CUDA (Pascal 535, Ampere/Ada 565, Hopper/Blackwell Open + Fabric Manager).
- **Multi-Hypervisor Portability**: Coexistence of `qemu-guest-agent`, `open-vm-tools`, Unraid `virtiofs`/`9p` host sharing, and ACPI clean power shutdown.
- **Bare-Metal Performance Engine**: NVMe I/O scheduling (`kyber`), BBR congestion control, automatic first-boot root expansion (`growpart`), and direct disk streaming (`lusoris-install-to-disk`).
- **Resilient Global Time**: Cryptographically authenticated Network Time Security (NTS) combining Cloudflare Anycast NTS and European Stratum-1 national laboratories (PTB, Netnod, SIDN, 3eck) with graceful fallback.

---

## 2. Architectural Invariants

1. **Self-Contained & Reproducible Builds**:
   The Packer templates must build cleanly via standalone QEMU/KVM locally or in CI without requiring an external hypervisor API.
2. **Declarative Version Manifest**:
   All upstream versions live in [`versions.json`](versions.json) and are ingested into Packer via `jsondecode()`.
3. **Modular Provisioners**:
   Provisioner shell scripts live under `packer/provisioners/` with prefix numbering (`00-`, `10-`, etc.). Scripts must enforce `set -euo pipefail` and pass ShellCheck with zero warnings.
4. **NASA/JPL Power of 10 Compliance**:
   Functions <= 60 lines, bounded loops, checked return codes, and zero linter warnings.
5. **NVIDIA Generational Segmentation**:
   - `nvidia-legacy`: NVIDIA 535 (Pascal / Volta).
   - `nvidia-mainstream`: NVIDIA 565 (Turing / Ampere).
   - `nvidia-modern`: NVIDIA 610 (Ada Lovelace RTX 4090 / Hopper).
   - `nvidia-bleeding`: NVIDIA 615 (Blackwell RTX 5090 / B200).
   - `nvidia-datacenter`: NVIDIA Open Kernel Modules + Fabric Manager (Hopper / Blackwell).
6. **Pre-cached Container Runtime**:
   Kubernetes node flavors support modular preheat profiles (`lean`, `cilium`, `calico`, `flannel`) injecting DaemonSets directly into containerd's `k8s.io` namespace.

---

## 3. The 4-Dimensional Flavor Matrix (26 Flavors)

| Workload Tier | Hardware Stack | Flavor Target | Key Components |
| :--- | :--- | :--- | :--- |
| **Base** | Generic (VirtIO) | `base-generic` | Minimal hardened OS, Anycast NTS, QEMU+VMware agents |
| **Base** | Intel GPU | `base-intel` | Intel Media Driver (`iHD`), Level Zero, vainfo, Battlemage Xe2 |
| **Base** | AMD GPU | `base-amd` | AMD Mesa VA-API (`radeonsi`), RADV Vulkan, AMDGPU DRM |
| **Base** | NVIDIA Legacy | `base-nvidia-legacy` | NVIDIA 535 driver branch, CUDA 12.2 (Pascal/Volta) |
| **Base** | NVIDIA Mainstream | `base-nvidia-mainstream`| NVIDIA 565 driver branch, CUDA 12.8 (RTX/Ampere) |
| **Base** | NVIDIA Bleeding | `base-nvidia-bleeding` | NVIDIA 615 driver branch, CUDA 13.4 (Blackwell RTX 5090) |
| **Base** | NVIDIA Datacenter | `base-nvidia-datacenter`| NVIDIA Open Kernel Modules, Fabric Manager (Hopper/Blackwell) |
| **Docker** | Generic (VirtIO) | `docker-generic` | Docker CE 29.8, Docker Compose v2, containerd, log rotation |
| **Docker** | Intel GPU | `docker-intel` | Docker CE + Intel Media/Compute + QuickSync passthrough |
| **Docker** | AMD GPU | `docker-amd` | Docker CE + AMD ROCm 10 compute runtime |
| **Docker** | NVIDIA Mainstream | `docker-nvidia` | Docker CE + NVIDIA Container Toolkit + CDI specifications |
| **Docker** | NVIDIA Bleeding | `docker-nvidia-bleeding`| Docker CE + NVIDIA 615 + NVIDIA Container Toolkit CDI |
| **Podman** | Generic (VirtIO) | `podman-generic` | Podman 5.x, Buildah, Skopeo, Quadlet, Netavark CNI |
| **Kubernetes**| Generic (VirtIO) | `k8s-node-generic` | containerd 2.3.5, kubelet/kubeadm 1.37.0, lean zero-preheat |
| **Kubernetes**| Generic (VirtIO) | `k8s-node-cilium` | containerd 2.3.5, preheated Cilium 1.20.1 & kube-vip 1.2.3 |
| **Kubernetes**| Generic (VirtIO) | `k8s-node-calico` | containerd 2.3.5, preheated Calico 3.32.2 & kube-vip 1.2.3 |
| **Kubernetes**| Generic (VirtIO) | `k8s-node-flannel` | containerd 2.3.5, preheated Flannel 0.28.9 & kube-vip 1.2.3 |
| **Kubernetes**| Intel GPU | `k8s-node-intel` | containerd 2.3.5 + Intel drivers + Intel K8s Device Plugin |
| **Kubernetes**| AMD GPU | `k8s-node-amd` | containerd 2.3.5 + AMD ROCm 10 + AMD K8s Device Plugin |
| **Kubernetes**| NVIDIA Mainstream | `k8s-node-nvidia` | containerd 2.3.5 + NVIDIA 565 + NVIDIA K8s Device Plugin |
| **Kubernetes**| NVIDIA Bleeding | `k8s-node-nvidia-bleeding`| containerd 2.3.5 + NVIDIA 615 + NVIDIA K8s Device Plugin |
| **AI Infer** | Generic (CPU) | `ai-infer-generic` | AMX, AVX-512, NUMA, vLLM/Ollama CPU, Docker CE |
| **AI Infer** | Intel GPU | `ai-infer-intel` | Intel Level Zero, OpenVINO, IPEX-LLM, CDI, Docker CE |
| **AI Infer** | AMD GPU | `ai-infer-amd` | AMD ROCm 10, /dev/kfd, RDNA 3/4 & Instinct, CDI, Docker CE |
| **AI Infer** | NVIDIA Mainstream | `ai-infer-nvidia` | Transparent hugepages, numactl, vLLM/Ollama (NVIDIA 565) |
| **AI Infer** | NVIDIA Bleeding | `ai-infer-nvidia-bleeding`| Transparent hugepages, Blackwell RTX 5090 / B200 (NVIDIA 615) |

---

## 4. Build & Test Commands

```bash
make help               # Display all available targets
make lint               # Run packer validate, shellcheck, and yamllint
make test               # Run automated pytest verification suite
make fmt                # Format Packer HCL configurations
make build-base-generic # Build base-generic image via local QEMU/KVM
make build-docker-generic # Build docker-generic image
make build-k8s-generic  # Build k8s-node-generic image (lean)
make build-k8s-cilium   # Build k8s-node-cilium image (preheated)
make build-ai-infer-generic # Build CPU inference image
make build-ai-infer-intel   # Build Intel Arc inference image
make build-ai-infer-amd     # Build AMD ROCm inference image
make build-ai-infer-nvidia  # Build NVIDIA 565 inference image
make build-ai-infer-nvidia-bleeding # Build ai-infer-nvidia-bleeding image
```
