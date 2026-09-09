# Base Flavors

The `base-*` tier provides a zero-bloat, hardened Linux foundation for general-purpose virtual machines, bare-metal servers, and cloud instances.

## Key Characteristics

- **Distro Base**: Ubuntu 26.04 LTS (Resolute).
- **Purged Components**: `snapd`, `lxd`, Ubuntu Pro client, telemetry daemons, motd news, unused locales, and man pages.
- **Time Synchronization**: Network Time Security (NTS) chrony client with multi-tier Anycast (Cloudflare) and national metrology institutes (PTB, Netnod, SIDN, 3eck).
- **Hypervisor Coexistence**: Both `qemu-guest-agent` and `open-vm-tools` are installed; each daemon remains dormant unless booted on its matching hypervisor.
- **Portability**: Cloud-init operates with unrestricted datasources for seamless compatibility with Proxmox, Unraid, VMware, AWS, GCP, and Bare-Metal.

## Available Flavors

### `base-generic`
Lightweight headless compute image. Suitable for web servers, databases, and microVMs.

### `base-intel`
Includes Intel Media Driver (`iHD`), Level Zero runtime (`libze`), OpenCL compute, and diagnostics (`vainfo`, `clinfo`).

### `base-amd`
Includes Mesa Gallium `radeonsi` VA-API, RADV Vulkan drivers, and AMDGPU DRM runtime.

### `base-nvidia-*`
Segregated into three hardware generations:
- `base-nvidia-legacy`: NVIDIA 535 driver branch for Pascal and Volta.
- `base-nvidia-mainstream`: NVIDIA 565+ driver branch for Turing, Ampere, and Ada.
- `base-nvidia-datacenter`: NVIDIA Open Kernel Modules and Fabric Manager for Hopper and Blackwell.
