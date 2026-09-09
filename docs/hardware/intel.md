# Intel GPU Acceleration Stack

Supported hardware: Intel Core Gen 8–15 (UHD/Iris Xe), Intel Arc Alchemist (A380, A750, A770), Intel Arc Battlemage (B580, B570), and Intel Data Center Flex series.

## Included Packages & Runtimes

- **Intel Media Driver (`intel-media-va-driver-non-free`)**: Hardware-accelerated video decode and encode (AV1, HEVC, H.264, VP9) via VA-API.
- **Level Zero Runtime (`libze1`, `libze-intel-gpu1`)**: Low-level hardware abstraction interface for Intel GPUs.
- **oneVPL (`libvpl2`)**: Intel oneAPI Video Processing Library.
- **OpenCL (`intel-opencl-icd`)**: Intel OpenCL compute runtime for compute workloads.
- **Diagnostics**: `vainfo`, `clinfo`, and `hwinfo` pre-installed for hardware verification.

## Verifying Intel GPU Acceleration

```bash
# Verify VA-API hardware acceleration
vainfo --display drm --device /dev/dri/renderD128

# Verify OpenCL compute platform
clinfo -l
```
