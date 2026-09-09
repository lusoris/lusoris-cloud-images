# The 4D Flavor Matrix

`lusoris-cloud-images` structures operating system images across four orthogonal dimensions: **Platform**, **Workload**, **Hardware Acceleration**, and **Security Hardening**.

---

## Interactive Flavor Matrix

| Flavor Name | Workload | Hardware Stack | Included Components | Primary Target Platforms |
| :--- | :--- | :--- | :--- | :--- |
| **`base-generic`** | Minimal OS | VirtIO / CPU | Zero bloat, Anycast NTS, QEMU+VMware agents | Proxmox, Unraid, VMware, KVM, Cloud |
| **`base-intel`** | Minimal OS | Intel GPU | Intel Media Driver (`iHD`), Level Zero, vainfo, clinfo | Proxmox PCIe passthrough, Bare-Metal |
| **`base-amd`** | Minimal OS | AMD GPU | Mesa Gallium `radeonsi`, RADV Vulkan, AMDGPU DRM | Proxmox PCIe passthrough, Bare-Metal |
| **`base-nvidia-legacy`** | Minimal OS | NVIDIA Pascal/Volta | NVIDIA 535 driver, CUDA 12.2, CDI toolkit | GTX 1080, P4, P40, P100, V100 |
| **`base-nvidia-mainstream`**| Minimal OS | NVIDIA RTX/Ampere/Ada | NVIDIA 565+ driver, CUDA 12.8+, modern CDI | RTX 30/40, A100, L4, L40S |
| **`base-nvidia-datacenter`**| Minimal OS | NVIDIA Hopper/Blackwell | NVIDIA Open Modules, Fabric Manager, NVLink | H100, H200, B100, B200, GB200 |
| **`docker-generic`** | Docker Appliance| VirtIO / CPU | Docker CE, Docker Compose v2, log rotation | Standalone microservices, Homelab |
| **`docker-intel`** | Docker Appliance| Intel GPU | Docker CE + Intel QuickSync passthrough | Jellyfin, Plex, Intel OpenVINO |
| **`docker-amd`** | Docker Appliance| AMD GPU | Docker CE + AMD ROCm 6.x compute | PyTorch, ROCm ML containers |
| **`docker-nvidia`** | Docker Appliance| NVIDIA Mainstream | Docker CE + NVIDIA Container Toolkit | GPU containers, Ollama, CUDA dev |
| **`podman-generic`** | Rootless OCI | VirtIO / CPU | Podman 5.x, Buildah, Skopeo, Quadlet | Daemonless rootless microservices |
| **`k8s-node-generic`**| K8s Worker | VirtIO / CPU | containerd 2.x, kubelet, Cilium/kube-vip cached | Production K8s cluster node |
| **`k8s-node-intel`** | K8s Worker | Intel GPU | containerd 2.x + Intel K8s Device Plugin | K8s GPU worker (Intel Arc/Flex) |
| **`k8s-node-amd`** | K8s Worker | AMD GPU | containerd 2.x + AMD K8s Device Plugin | K8s GPU worker (AMD Radeon/ROCm) |
| **`k8s-node-nvidia`**| K8s Worker | NVIDIA Mainstream | containerd 2.x + NVIDIA K8s Device Plugin | K8s GPU worker (NVIDIA RTX/A100) |
| **`ai-infer-nvidia`**| AI Inference | NVIDIA Mainstream | Hugepages, numactl, vLLM & Ollama hooks | Dedicated LLM inference appliance |

---

## Build Targets

Every flavor maps cleanly to a Make target for local QEMU builds:

```bash
make build-base-generic
make build-docker-generic
make build-docker-intel
make build-docker-nvidia
make build-k8s-generic
make build-k8s-intel
make build-ai-infer-nvidia
```
