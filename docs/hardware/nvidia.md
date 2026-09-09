# NVIDIA Generational Acceleration Stacks

To prevent driver incompatibilities and runtime failures across disparate GPU microarchitectures, `lusoris-cloud-images` provides three distinct generational flavors.

---

## 1. NVIDIA Legacy (`*-nvidia-legacy`)

- **Microarchitectures**: Pascal (sm_60, sm_61) and Volta (sm_70).
- **Target GPUs**: GTX 1070/1080/1080Ti, Tesla P4, P40, P100, Titan Xp, Tesla V100.
- **Driver & CUDA**: NVIDIA 535 headless branch with CUDA 12.2.
- **Why this exists**: Modern CUDA 12.8+ and 560+ driver branches drop support for Pascal hardware. This flavor guarantees stability and compute capability for legacy hardware.

---

## 2. NVIDIA Mainstream (`*-nvidia-mainstream` / `*-nvidia`)

- **Microarchitectures**: Turing (sm_75), Ampere (sm_80, sm_86), Ada Lovelace (sm_89).
- **Target GPUs**: RTX 20/30/40 series, Tesla T4, A100, A10, A30, L4, L40, RTX 6000 Ada.
- **Driver & CUDA**: NVIDIA 565+ headless branch with CUDA 12.8+.
- **Container Device Interface**: Modern CDI v0.6+ specifications generated at `/etc/cdi/nvidia.yaml`.

---

## 3. NVIDIA Datacenter (`*-nvidia-datacenter`)

- **Microarchitectures**: Hopper (sm_90) and Blackwell (sm_100).
- **Target GPUs**: H100, H200, B100, B200, GB200 NVL.
- **Open Kernel Modules**: Installs official `nvidia-open` kernel modules.
- **Fabric Manager**: Pre-configures and enables `nvidia-fabricmanager` for NVLink and NVSwitch mesh inter-GPU communication.
- **GPUDirect Storage**: Configured with `nvidia-gds` and high-speed RDMA hooks.
