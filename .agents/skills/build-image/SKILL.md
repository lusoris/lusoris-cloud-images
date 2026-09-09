---
name: build-image
description: Build a specific Lusoris cloud or k8s node image flavor (generic, intel, amd, nvidia) via Packer QEMU or Proxmox
---

# /build-image

Build a specialized OS image using Packer HCL2.

## Usage

```bash
# Build standalone QEMU QCOW2 image locally
make build-generic
make build-intel
make build-amd
make build-nvidia
make build-k8s-generic
make build-k8s-intel

# Or run directly via Packer
cd packer
packer build -only="base-intel.qemu.image" .
```

## Available Flavors

- `base-generic`: Minimal, hardened Ubuntu cloud image.
- `base-intel`: Includes Intel Media Driver, Level Zero, and oneAPI runtime.
- `base-amd`: Includes Mesa Gallium RADV, AMDGPU DRM, and ROCm essentials.
- `base-nvidia`: Includes NVIDIA Container Toolkit and driver repository hooks.
- `k8s-node-generic`: Kubernetes node with containerd, kubelet, and pre-cached daemonsets.
- `k8s-node-intel`: Kubernetes node with Intel GPU device plugin and drivers.
- `k8s-node-amd`: Kubernetes node with AMD GPU device plugin and drivers.
- `k8s-node-nvidia`: Kubernetes node with NVIDIA GPU device plugin and drivers.
