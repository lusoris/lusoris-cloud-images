# The 4D Flavor Matrix

`lusoris-cloud-images` structures operating system images across four orthogonal dimensions: **Platform**, **Workload**, **Hardware Acceleration**, and **Security Hardening**.

---

## Comprehensive 39-Flavor Matrix

| Flavor Name | Workload Tier | Hardware Stack | Kernel Profile | Preheat Profile | Key Components & Target Platforms |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **`base-generic`** | Minimal OS | VirtIO / CPU | `generic` | None | Minimal OS, Anycast NTS, QEMU+VMware agents |
| **`base-intel`** | Minimal OS | Intel Xe/Arc/Xe2 | `generic` | None | Intel Media Driver (`iHD`), Level Zero, vainfo, Battlemage Xe2 |
| **`base-amd`** | Minimal OS | AMD Mesa / RADV | `generic` | None | Mesa Gallium `radeonsi`, RADV Vulkan, AMDGPU DRM |
| **`base-nvidia-legacy`** | Minimal OS | NVIDIA Pascal/Volta | `generic` | None | NVIDIA 535 driver, CUDA 12.2, GTX 1080/P4/P40/P100/V100 |
| **`base-nvidia-mainstream`** | Minimal OS | NVIDIA Turing/Ampere | `generic` | None | NVIDIA 565 driver, CUDA 12.8, RTX 20/30/40, A100, L4 |
| **`base-nvidia-modern`** | Minimal OS | NVIDIA Ada/Hopper | `generic` | None | NVIDIA 610 driver, CUDA 13.3, RTX 4080/4090, L40S, H100 |
| **`base-nvidia-bleeding`** | Minimal OS | NVIDIA Blackwell | `generic` | None | NVIDIA 615 driver, CUDA 13.4, RTX 5090, B200 |
| **`base-nvidia-datacenter`** | Minimal OS | NVIDIA Hopper/Blackwell | `baremetal` | None | NVIDIA 615 Open Modules, Fabric Manager, NVLink mesh |
| **`docker-generic`** | Container Host | VirtIO / CPU | `generic` | None | Docker CE 29.8, Docker Compose v2, systemd cgroup |
| **`docker-intel`** | Container Host | Intel GPU | `generic` | None | Docker CE + Intel QuickSync passthrough + CDI spec |
| **`docker-amd`** | Container Host | AMD ROCm 10 | `generic` | None | Docker CE + AMD ROCm 10 compute runtime + CDI spec |
| **`docker-nvidia`** | Container Host | NVIDIA Mainstream | `generic` | None | Docker CE + NVIDIA 565 + NVIDIA Container Toolkit CDI |
| **`docker-nvidia-modern`** | Container Host | NVIDIA Modern | `generic` | None | Docker CE + NVIDIA 610 + NVIDIA Container Toolkit CDI |
| **`docker-nvidia-bleeding`** | Container Host | NVIDIA Bleeding | `generic` | None | Docker CE + NVIDIA 615 + NVIDIA Container Toolkit CDI |
| **`podman-generic`** | Rootless OCI | VirtIO / CPU | `generic` | None | Podman 5.x, Buildah, Skopeo, Quadlet, Netavark CNI |
| **`k8s-node-generic`** | K8s Worker | VirtIO / CPU | `k8s` | `lean` | containerd 2.3.5, kubelet 1.37.0, zero pre-cache |
| **`k8s-node-cilium`** | K8s Worker | VirtIO / CPU | `k8s` | `cilium` | containerd 2.3.5, preheated Cilium 1.20.1 & kube-vip 1.2.3 |
| **`k8s-node-calico`** | K8s Worker | VirtIO / CPU | `k8s` | `calico` | containerd 2.3.5, preheated Calico 3.32.2 & kube-vip 1.2.3 |
| **`k8s-node-flannel`** | K8s Worker | VirtIO / CPU | `k8s` | `flannel` | containerd 2.3.5, preheated Flannel 0.28.9 & kube-vip 1.2.3 |
| **`k8s-node-intel`** | K8s Worker | Intel Arc/Xe2 | `k8s` | `cilium` | containerd 2.3.5 + Intel drivers + Intel K8s Plugin v0.36.0 |
| **`k8s-node-amd`** | K8s Worker | AMD GPU | `k8s` | `cilium` | containerd 2.3.5 + AMD ROCm 10 + AMD K8s Plugin v1.37.0 |
| **`k8s-node-nvidia`** | K8s Worker | NVIDIA Mainstream | `k8s` | `cilium` | containerd 2.3.5 + NVIDIA 565 + NVIDIA K8s Plugin v0.20.0 |
| **`k8s-node-nvidia-modern`** | K8s Worker | NVIDIA Modern | `k8s` | `cilium` | containerd 2.3.5 + NVIDIA 610 + NVIDIA K8s Plugin v0.20.0 |
| **`k8s-node-nvidia-bleeding`** | K8s Worker | NVIDIA Bleeding | `k8s` | `cilium` | containerd 2.3.5 + NVIDIA 615 + NVIDIA K8s Plugin v0.20.0 |
| **`k3s-agent-generic`** | K3s Worker | VirtIO / CPU | `k8s` | None | Lightweight K3s agent, containerd, Flannel (< 300MB RAM) |
| **`k3s-agent-intel`** | K3s Worker | Intel QuickSync | `k8s` | None | K3s agent + Intel Media Driver (`iHD`) + QuickSync passthrough |
| **`k3s-agent-amd`** | K3s Worker | AMD ROCm 10 | `k8s` | None | K3s agent + AMD ROCm 10 compute runtime + RADV Vulkan |
| **`k3s-agent-nvidia`** | K3s Worker | NVIDIA Mainstream | `k8s` | None | K3s agent + NVIDIA 565 + Container Toolkit CDI |
| **`k3s-server-generic`** | K3s Server | VirtIO / CPU | `k8s` | None | K3s standalone control plane + embedded SQLite + local-path |
| **`cloudnative-generic`** | Immutable Host | VirtIO / CPU | `generic` | None | Read-only root hardening, ephemeral tmpfs, containerd CDI |
| **`cloudnative-k8s`** | Immutable Worker | VirtIO / CPU | `k8s` | `lean` | Read-only root hardening, containerd 2.3.5, kubelet 1.37.0 |
| **`cloudnative-storage`** | CNCF Storage | VirtIO / Baremetal | `baremetal` | None | NVMe-oF (TCP), OpenZFS 2.3, iSCSI, multipath, NFS |
| **`cloudnative-pg`** | Database Host | VirtIO / Baremetal | `ai-infer` | None | CloudNativePG tuning, hugepages, strict memory overcommit |
| **`ai-infer-generic`** | AI Inference | CPU High-Throughput | `ai-infer` | None | AMX, AVX-512, NUMA, vLLM / Ollama CPU, Docker CE |
| **`ai-infer-intel`** | AI Inference | Intel Xe/Arc/Xe2 | `ai-infer` | None | Intel Level Zero, OpenVINO, IPEX-LLM, CDI, Docker CE |
| **`ai-infer-amd`** | AI Inference | AMD ROCm 10 | `ai-infer` | None | AMD ROCm 10, /dev/kfd, RDNA 3/4 & Instinct, CDI, Docker CE |
| **`ai-infer-nvidia`** | AI Inference | NVIDIA Mainstream | `ai-infer` | None | NVIDIA 565, Transparent Hugepages, NUMA, vLLM, Docker CE |
| **`ai-infer-nvidia-modern`** | AI Inference | NVIDIA Modern | `ai-infer` | None | NVIDIA 610, Transparent Hugepages, NUMA, vLLM, Docker CE |
| **`ai-infer-nvidia-bleeding`**| AI Inference | NVIDIA Bleeding | `ai-infer` | None | NVIDIA 615, Blackwell RTX 5090 / B200, vLLM, Docker CE |

---

## Build Targets

Every flavor maps cleanly to a Make target for local QEMU builds:

```bash
# Base Cloud Flavors
make build-base-generic
make build-base-intel
make build-base-amd
make build-base-nvidia-legacy
make build-base-nvidia-mainstream
make build-base-nvidia-modern
make build-base-nvidia-bleeding
make build-base-nvidia-datacenter

# Container Appliances
make build-docker-generic
make build-docker-intel
make build-docker-amd
make build-docker-nvidia
make build-docker-nvidia-modern
make build-docker-nvidia-bleeding
make build-podman-generic

# Kubernetes Node Flavors
make build-k8s-generic        # Lean zero-preheat
make build-k8s-cilium         # Preheated Cilium & kube-vip
make build-k8s-calico         # Preheated Calico & kube-vip
make build-k8s-flannel        # Preheated Flannel & kube-vip
make build-k8s-intel          # Intel Arc/Xe2 GPU
make build-k8s-amd            # AMD ROCm 10 GPU
make build-k8s-nvidia         # NVIDIA 565 Mainstream
make build-k8s-nvidia-modern  # NVIDIA 610 Modern (RTX 4090)
make build-k8s-nvidia-bleeding # NVIDIA 615 Bleeding (RTX 5090)

# K3s Edge Fleet Flavors
make build-k3s-agent-generic   # Lightweight < 300MB RAM worker
make build-k3s-agent-intel     # Intel QuickSync / Xe transcoding worker
make build-k3s-agent-amd       # AMD ROCm 10 compute worker
make build-k3s-agent-nvidia    # NVIDIA 565 / CDI GPU worker
make build-k3s-server-generic  # Standalone master with local-path storage

# CloudNative & Storage Appliances
make build-cloudnative-generic # Immutable container host
make build-cloudnative-k8s     # Immutable Kubernetes node
make build-cloudnative-storage # CNCF storage appliance (NVMe-oF / ZFS)
make build-cloudnative-pg      # Production PostgreSQL / CNPG host

# AI Inference Appliances (All Vendors)
make build-ai-infer-generic   # CPU High-Throughput / AMX / AVX-512
make build-ai-infer-intel     # Intel Arc / Battlemage Xe2
make build-ai-infer-amd       # AMD ROCm 10 / RDNA 3/4 & Instinct
make build-ai-infer-nvidia    # NVIDIA 565 Mainstream
make build-ai-infer-nvidia-modern  # NVIDIA 610 Modern (RTX 4090)
make build-ai-infer-nvidia-bleeding # NVIDIA 615 Bleeding (RTX 5090)
```

