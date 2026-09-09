# AMD Radeon & ROCm Acceleration Stack

Supported hardware: AMD Radeon RX 6000/7000/8000 series, Ryzen APUs, Radeon Pro, and AMD Instinct MI200/MI300 series.

## Mesa vs ROCm Tiers

`lusoris-cloud-images` provides two distinct AMD stacks:

### 1. AMD Mesa Stack (`*-amd`)
- **Use Case**: Video transcoding, lightweight 3D rendering, desktop acceleration.
- **Packages**: `mesa-va-drivers` (`radeonsi`), `mesa-vulkan-drivers` (`radv`), `libdrm-amdgpu1`.
- **Diagnostics**: `vainfo`, `vulkan-tools`.

### 2. AMD ROCm Compute Stack (`*-amd-rocm`)
- **Use Case**: Machine learning, PyTorch, LLM inference, scientific compute.
- **Packages**: `rocm-hip-runtime`, `rocminfo`, `hip-runtime-amd`.
- **Permissions**: Udev rule pre-configured for `/dev/kfd` render group compute node access.

## Verifying AMD ROCm
```bash
rocminfo
```
