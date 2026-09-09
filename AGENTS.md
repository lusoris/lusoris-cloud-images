# AGENTS.md — Agent & Contributor Directives

> Authoritative operating guide for all autonomous engineering agents and human contributors in `lusoris-cloud-images`.

---

## 🌟 TOP-PRIORITY GLOBAL RULES

1. **Declarative Source of Truth**:
   All image definitions, provisioners, and CI pipelines live declaratively in this repository. Never assume or hand-mutate external state.
2. **Preserve Architectural Invariants**:
   Every invariant defined in Section 2 must be maintained across all modifications. If an edit risks violating an invariant, stop, verify, and resolve the invariant first.
3. **Docs & Code Synchrony**:
   Every user-discoverable change (new flavor, configuration variable, or provisioner step) must be reflected in the documentation ([README.md](README.md) and [ONBOARDING.md](ONBOARDING.md)) in the **exact same commit**.
4. **All Documentation in English**:
   All commit messages, code comments, documentation, and agent reports must be written in a neutral, professional English register.

---

## 1. Mission & Purpose

`lusoris-cloud-images` produces clean, hardened, production-ready cloud and bare-metal OS images optimized for virtualization (Proxmox, KVM, QEMU), cloud-init, and Kubernetes clusters.

Key capabilities:
- **Zero Base Bloat**: Purges `snapd`, `lxd`, Ubuntu Pro telemetry, motd news, and unneeded documentation/locales.
- **Hardware Acceleration Flavors**: Dedicated flavors for Intel, AMD, and NVIDIA eliminate competing driver bloat.
- **Instant Kubernetes Boot**: Pinned containerd 2.x, kubelet, and core DaemonSets (`cilium`, `kube-vip`, device plugins) are pre-baked into the image to eliminate first-boot network pulling delays.
- **Authoritative Time**: Hostname-based PTB NTS policy (`ptbtime1.ptb.de` - `ptbtime4.ptb.de`) baked in via chrony.

---

## 2. Architectural Invariants

1. **Self-Contained & Reproducible Builds**:
   - The Packer templates must build cleanly via standalone QEMU/KVM locally or in CI without requiring an external hypervisor API.
2. **Modular Provisioners**:
   - Provisioner shell scripts must live under `packer/provisioners/` with prefix numbering (`00-`, `10-`, etc.).
   - Scripts must enforce `set -euo pipefail` and pass ShellCheck with zero warnings.
3. **NASA/JPL Power of 10 Compliance**:
   - Short functions (<= 60 lines), bounded loops, checked return codes, and zero linter warnings.
4. **Lean GPU Stacks**:
   - `:intel` installs Intel Media Driver (`iHD`), Level Zero (`libze`), and oneAPI runtime.
   - `:amd` installs Mesa Gallium RADV and AMDGPU DRM.
   - `:nvidia` installs NVIDIA Container Toolkit and headless driver hooks.
5. **Pre-cached Container Runtime**:
   - `:k8s-*` node flavors must pre-pull essential cluster images directly into containerd's `k8s.io` namespace.

---

## 3. Image Flavor Matrix

| Flavor | Target Platform / Hardware | Acceleration Stack | Included Components |
| :--- | :--- | :--- | :--- |
| **`base-generic`** | General purpose VMs & Cloud instances | VirtIO / Headless | Minimal hardened OS, PTB NTS, qemu-guest-agent |
| **`base-intel`** | Intel Core Gen 8–14+, Arc Alchemist/Battlemage | Intel Media Driver (`iHD`), Level Zero, oneAPI | Intel compute/media drivers, vainfo, clinfo |
| **`base-amd`** | AMD Radeon RX series, Ryzen APUs | Mesa Gallium (`radeonsi`), RADV Vulkan | AMDGPU DRM, Mesa VA-API/Vulkan, vainfo |
| **`base-nvidia`** | NVIDIA Pascal through Blackwell | NVIDIA Container Toolkit | nvidia-container-toolkit, CDI hooks |
| **`k8s-node-generic`**| Kubernetes Worker / Control-Plane | VirtIO / CPU | containerd 2.x, kubelet/kubeadm, pre-cached Cilium/kube-vip |
| **`k8s-node-intel`**  | Kubernetes Worker with Intel GPU | Intel Arc/iGPU + containerd | Intel drivers + Intel K8s Device Plugin pre-cached |
| **`k8s-node-amd`**    | Kubernetes Worker with AMD GPU | AMD Radeon + containerd | AMD drivers + AMD K8s Device Plugin pre-cached |
| **`k8s-node-nvidia`** | Kubernetes Worker with NVIDIA GPU | NVIDIA GPU + containerd | NVIDIA toolkit + NVIDIA K8s Device Plugin pre-cached |

---

## 4. Build & Test Commands

```bash
make help               # Display all available targets
make lint               # Run packer validate, shellcheck, and yamllint
make test               # Run automated pytest verification
make fmt                # Format Packer HCL configurations
make build-generic      # Build base-generic image via local QEMU/KVM
make build-intel        # Build base-intel image via local QEMU/KVM
make build-k8s-intel    # Build k8s-node-intel image via local QEMU/KVM
```
