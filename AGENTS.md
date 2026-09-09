# AGENTS.md — Agent & Contributor Directives

> Authoritative operating guide for all autonomous engineering agents and human contributors in `lusoris-cloud-images`.
>
> **Read [`docs/principles.md`](docs/principles.md) before changing this repository.** It is the project-wide engineering and architecture contract. Then consult [`docs/repository-rule-crosswalk.md`](docs/repository-rule-crosswalk.md) for fleet standards cross-walked from `VMAFx/vmafx` and `20-watts-was-enough`.

---

## 🌟 TOP-PRIORITY GLOBAL RULES

These rules apply to ALL agents, ALL tools, and ALL commits — without exception:

1. **Read `docs/principles.md` First**: It defines the authority classes, Holzmann Power of 10 adaptations, and architectural contracts.
2. **Single Source of Truth (`versions.json`)**: Never hardcode distribution URLs, Kubernetes versions, container tags, or driver branches in Packer templates or shell provisioners. All versions must originate from [`versions.json`](versions.json) and be injected via Packer environment variables.
3. **Trunk-Based PR Merge Flow**: Direct commits to `main` are strictly prohibited. Always create a short-lived branch (`feat/*`, `fix/*`, `chore/*`), run all local quality gates, push, and open a PR with `gh pr create`. Merges require passing the `required-checks` aggregator.
4. **Docs & Code Synchrony**: Every user-discoverable change (new flavor, configuration variable, or provisioner step) must be reflected in documentation ([README.md](README.md) and [`docs/`](docs/)) in the **exact same commit/PR**.
5. **NASA/JPL Power of 10 Compliance**: All shell provisioner functions must be $\le$ 60 lines, enforce `set -euo pipefail`, check return codes, and pass ShellCheck with zero warnings.
6. **Privacy & Zero-Leak Invariant**: Never commit private RFC 1918 IP addresses (`10.x`, `192.168.x`, `172.16-31.x`) or local workstation home paths. Use standard documentation placeholders (`192.0.2.x`, `pve.example.com`).
7. **All Documentation in English**: All commit messages, code comments, documentation, and agent reports must be written in a neutral, professional English register.

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

## 2. Conventional Entry Points & Skills Library

Autonomous agents should utilize specialized project skills under `.agents/skills/`:

| Task | Skill Entry Point | Description |
| :--- | :--- | :--- |
| **Build OS Image** | [`.agents/skills/build-image/SKILL.md`](.agents/skills/build-image/SKILL.md) | Build image flavor via Packer QEMU or Proxmox |
| **Test Image & Config** | [`.agents/skills/test-image/SKILL.md`](.agents/skills/test-image/SKILL.md) | Run automated pytest verification suite |
| **Lint Entire Repo** | [`.agents/skills/lint-all/SKILL.md`](.agents/skills/lint-all/SKILL.md) | Run Packer validate, ShellCheck, Yamllint, shfmt |
| **Format All Files** | [`.agents/skills/format-all/SKILL.md`](.agents/skills/format-all/SKILL.md) | Format shell (`shfmt`), Packer (`packer fmt`), YAML |
| **Add New Flavor** | [`.agents/skills/add-flavor/SKILL.md`](.agents/skills/add-flavor/SKILL.md) | Add flavor to manifest, HCL, tests, and docs |
| **Draft Commit Message** | [`.agents/skills/dev-llm-commitmsg/SKILL.md`](.agents/skills/dev-llm-commitmsg/SKILL.md) | Conventional Commits drafting |
| **Regenerate Docs** | [`.agents/skills/regen-docs/SKILL.md`](.agents/skills/regen-docs/SKILL.md) | Strict Material for MkDocs build |
| **Prepare Release** | [`.agents/skills/prep-release/SKILL.md`](.agents/skills/prep-release/SKILL.md) | Pre-release verification checklist |

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

## 4. Hard Rules

1. **Single Source of Truth**: Never hardcode versions, tags, or driver branches in templates or scripts (§3).
2. **Never `git push --force` to `main`**.
3. **Never commit directly to `main`** — pull requests with squash or rebase merge only.
4. **Never merge without `make lint` + `make test` green** locally and in CI.
5. **Every commit message follows Conventional Commits** (`type(scope): subject`).
6. **Every new script or code file starts with license header** (`Copyright 2026 Lusoris`).
7. **Every user-discoverable surface ships human-readable documentation** under `docs/` in the same PR.
8. **Every non-trivial architectural or policy decision ships an ADR** under [`docs/adr/`](docs/adr/) before or alongside the code.
9. **Power of 10 compliance**: Shell functions $\le$ 60 lines, `set -euo pipefail`, bounded loops, zero linter warnings.
10. **Privacy & Zero-Leak invariant**: Zero private RFC 1918 IPs, zero `/home/*` workstation paths.
11. **Worktree discipline**: Background coding agents run in isolated git worktrees or dedicated branches; never execute concurrent tasks in the main worktree.
12. **All documentation in English**: Commit messages, code comments, and documentation must be in neutral, professional English.
13. **Interaction style — ask only on real forks**: Act on unambiguous work directly. When a genuine fork arises (destructive trade-off, target ambiguity), ask concise, structured questions.
