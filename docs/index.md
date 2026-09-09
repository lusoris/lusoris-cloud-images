# lusoris-cloud-images

> Enterprise-grade, hardened, hardware-accelerated cloud and bare-metal OS images with pre-baked runtimes.

---

## What is lusoris-cloud-images?

`lusoris-cloud-images` is an automated OS image forge that builds production-ready, zero-bloat images for **virtualization** (Proxmox VE, Unraid, VMware ESXi, QEMU/KVM), **bare-metal servers**, and **public clouds**.

Instead of deploying generic stock distributions that spend minutes pulling gigabytes of packages and container layers on first boot, `lusoris-cloud-images` provides:

- **Zero Base Bloat**: Complete purge of `snapd`, `lxd`, Ubuntu Pro telemetry, and unneeded documentation.
- **Hardware Acceleration Tiers**: Tailored GPU driver stacks for Intel Arc/Xe, AMD Mesa & ROCm, and NVIDIA generational CUDA (Pascal 535, Ampere/Ada 565, Hopper/Blackwell Open Modules + Fabric Manager).
- **Multi-Hypervisor Portability**: Coexisting `qemu-guest-agent` and `open-vm-tools` plus Unraid `virtiofs` and `9p` host sharing out of the box.
- **Bare-Metal Performance Engine**: NVMe low-latency I/O scheduling, BBR congestion control, auto-growroot on first boot, and streaming direct flash (`lusoris-install-to-disk`).
- **Resilient Global Time**: Cryptographically authenticated Network Time Security (NTS) using Cloudflare Anycast and European national metrology institutes (PTB, Netnod, SIDN, 3eck).
- **Single Source of Truth (`versions.json`)**: Every upstream package, container image tag, and driver branch is centrally defined and automated via Renovate.

---

## Architecture Overview

```mermaid
graph TD
    Upstream[Ubuntu Resolute Cloud Base] --> Forge[Packer Build Engine]
    BOM[Single Source of Truth: versions.json] --> Forge

    Forge --> Base[00-base-strip: Purge snapd & telemetry]
    Base --> Agents[05-hypervisor-agents: QEMU + VMware + Unraid VirtFS]
    Agents --> Time[10-network-time: Anycast NTS chrony]
    Time --> Hardening[20-kernel-sysctl: CIS Baseline & BBR]
    Hardening --> BM[25-baremetal-tuning: NVMe sched & growroot]

    BM --> H_Gen[Generic VirtIO]
    BM --> H_Intel[30-gpu-intel: Level Zero & VA-API]
    BM --> H_AMD[31-gpu-amd-mesa / 32-gpu-amd-rocm]
    BM --> H_NV[33/34/35-gpu-nvidia: Legacy / Mainstream / Datacenter]

    H_Gen --> W_Base[Base Minimal OS]
    H_Intel --> W_Dock[40-docker-runtime: Docker CE + Compose]
    H_AMD --> W_Pod[41-podman-runtime: Podman Quadlet]
    H_NV --> W_K8s[50/55-k8s: containerd 2.x + Pre-cached Cilium]
    H_NV --> W_AI[60-ai-infer: vLLM & Ollama Runtime]

    W_Base --> OUT[Artifacts: .qcow2.zst / .raw.zst / .vmdk.zst]
    W_Dock --> OUT
    W_Pod --> OUT
    W_K8s --> OUT
    W_AI --> OUT
```

---

## Quick Navigation

- [Explore the 4D Flavor Matrix](flavors/matrix.md)
- [Proxmox VE Deployment Guide](platforms/proxmox.md)
- [Unraid VM & VirtFS Guide](platforms/unraid.md)
- [VMware ESXi Import Guide](platforms/vmware.md)
- [Bare-Metal NVMe Flashing Guide](platforms/baremetal.md)
- [Architecture Decision Records (ADRs)](adr/README.md)

