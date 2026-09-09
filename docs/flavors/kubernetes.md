# Kubernetes Node Flavors

`k8s-node-*` flavors eliminate first-boot container image pulling latency by pre-caching essential cluster DaemonSets directly into containerd's `k8s.io` namespace.

## Pre-Baked Runtimes

- **Container Runtime**: `containerd 2.x` configured with `SystemdCgroup = true`.
- **Node Binaries**: Pinned `kubelet`, `kubeadm`, and `kubectl` (held via `apt-mark hold`).
- **Networking**: `br_netfilter` loaded, bridge sysctls active, swap permanently masked.

## Pre-Cached Core DaemonSets

All image tags are declared centrally in `versions.json`:

- `registry.k8s.io/pause:3.10`
- `registry.k8s.io/coredns/coredns:v1.12.0`
- `quay.io/cilium/cilium:v1.17.1`
- `ghcr.io/kube-vip/kube-vip:v0.8.9`
- `prom/node-exporter:v1.9.0`

## Hardware-Specific Node Flavors

- **`k8s-node-generic`**: Standard CPU worker node.
- **`k8s-node-intel`**: Pre-pulls `intel/intel-gpu-plugin` with Intel Media/Level Zero runtime.
- **`k8s-node-amd`**: Pre-pulls `rocm/k8s-device-plugin` with AMD ROCm compute runtime.
- **`k8s-node-nvidia`**: Pre-pulls `nvcr.io/nvidia/k8s-device-plugin` with NVIDIA Container Toolkit.
