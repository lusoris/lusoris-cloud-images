# ADR 0003: NVIDIA Multi-Generational CUDA & Driver Segmentation

## Status
Accepted

## Context
NVIDIA driver releases regularly deprecate older GPU architectures (e.g. CUDA 12.8 drops Pascal sm_60/61). Conversely, newer Hopper and Blackwell GPUs require Open Kernel Modules and Fabric Manager for NVLink. A single monolithic NVIDIA image causes driver breakage on older hardware and missing features on cutting-edge chips.

## Decision
We partition NVIDIA support into three dedicated provisioners and flavor tiers:
1. `*-nvidia-legacy`: NVIDIA 535 branch (CUDA 12.2) for Pascal and Volta.
2. `*-nvidia-mainstream`: NVIDIA 565+ branch (CUDA 12.8+) for Turing, Ampere, and Ada.
3. `*-nvidia-datacenter`: NVIDIA Open Kernel Modules + Fabric Manager for Hopper and Blackwell.

## Consequences
- Pascal users retain fully functioning CUDA without driver panics.
- Datacenter operators get turnkey NVLink mesh networking without manual setup.
