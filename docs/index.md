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
flowchart TD
    subgraph Inputs["1. Upstream & Declarative SSOT"]
        Upstream["Ubuntu 26.04 Cloud Base<br/><small>Noble / Resolute Minimal Image</small>"]
        SSOT[("versions.json<br/><small>Single Source of Truth (BOM)</small>")]
    end

    subgraph Core["2. Hardened Foundation (Stages 00–25)"]
        S0["00-base-strip<br/><small>Purge snapd & telemetry</small>"]
        S1["05-hypervisor-agents<br/><small>QEMU + VMware + VirtFS</small>"]
        S2["10-network-time<br/><small>Multi-peer Anycast NTS</small>"]
        S3["20-kernel-sysctl<br/><small>CIS L2 & BBR Congestion</small>"]
        S4["25-baremetal-tuning<br/><small>NVMe mq-deadline & ZRAM</small>"]
        S0 --> S1 --> S2 --> S3 --> S4
    end

    subgraph Tiers["3. The 4D Production Matrix (44 Flavors across 7 Tiers)"]
        direction TB
        T1["Tier 1: Minimal Base OS<br/><small>Generic · Intel · AMD · NVIDIA 535/565/610/615/Open (8)</small>"]
        T2["Tier 2: Container Hosts<br/><small>Docker CE · Podman Quadlet · GPU Passthrough (7)</small>"]
        T3["Tier 3: Enterprise K8s Nodes<br/><small>containerd 2.3.5 · Cilium / Calico / Flannel · kube-vip (9)</small>"]
        T4["Tier 4: K3s Edge Fleet<br/><small>Agent Flavors · Server Master · GPU Passthrough (5)</small>"]
        T5["Tier 5: CloudNative & Storage<br/><small>Immutable Read-Only · NVMe-oF · ZFS · CNPG (4)</small>"]
        T6["Tier 6: AI & LLM Inference<br/><small>NUMA · THP · vLLM · Ollama · OpenVINO (6)</small>"]
        T7["Tier 7: Homelab Appliances<br/><small>Vision NVR · Gateway DNS · Media · CI Runner · Game Server (5)</small>"]
    end

    subgraph Delivery["4. Universal Hypervisor & Bare-Metal Delivery"]
        Artifacts[("Production Artifacts<br/><small>.qcow2.zst · .raw.zst · .vmdk.zst</small>")]
        Platforms(["Proxmox VE · Unraid · VMware ESXi · Cloud Providers · Bare-Metal Install"])
        Artifacts --> Platforms
    end

    Inputs --> Core
    Core --> Tiers
    Tiers --> Artifacts
```

---

## Quick Navigation

- [Explore the 4D Flavor Matrix](flavors/matrix.md)
- [Proxmox VE Deployment Guide](platforms/proxmox.md)
- [Unraid VM & VirtFS Guide](platforms/unraid.md)
- [VMware ESXi Import Guide](platforms/vmware.md)
- [Bare-Metal NVMe Flashing Guide](platforms/baremetal.md)
- [Architecture Decision Records (ADRs)](adr/README.md)

