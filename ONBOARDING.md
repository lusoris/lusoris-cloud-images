# Onboarding Guide: lusoris-cloud-images

> Welcome to `lusoris-cloud-images`! This guide provides a complete, step-by-step walkthrough to get you from a fresh workstation to building, testing, verifying, and contributing production-hardened cloud and bare-metal OS images.

---

## 1. Mental Model & Architecture

### What is `lusoris-cloud-images`?
`lusoris-cloud-images` is an automated OS image forge built strictly on **Ubuntu 26.04 LTS (Resolute)**. It produces minimal, stripped, security-hardened, and hardware-accelerated images (`.qcow2`, `.raw`, `.vmdk`, and Proxmox templates).

Instead of booting generic stock distribution images that waste minutes pulling gigabytes of packages and container layers on first boot, this forge bakes everything needed ahead of time:
- **Zero Base Bloat**: Purges `snapd`, Ubuntu Pro telemetry daemons, motd news, and unneeded documentation.
- **Single Source of Truth (`versions.json`)**: All upstream URLs, Kubernetes binaries, container tags, and driver branches are managed centrally.
- **Hardware Acceleration**: Tailored driver stacks for Intel Arc/Battlemage Xe2, AMD Mesa/ROCm, and NVIDIA generational CUDA (Pascal 535, Ampere 565, Blackwell 615, and Datacenter Open Modules).
- **Container Standards**: Container Device Interface (CDI) at `/etc/cdi/`, Cgroup v2, OverlayFS metacopy acceleration, and modern container runtimes (Docker CE 29.8, Podman 5.x, containerd 2.3.5).
- **Resilient Global Time**: Cryptographically authenticated Network Time Security (NTS) using Cloudflare Anycast and European national metrology institutes (PTB, Netnod, SIDN, 3eck).

### How the Build Pipeline Works

```text
  ┌────────────────────────────────────────────────────────┐
  │         Single Source of Truth: versions.json          │
  └───────────────────────────┬────────────────────────────┘
                              │ jsondecode()
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │                 Packer Engine (HCL2)                   │
  │     (variables.pkr.hcl, sources.pkr.hcl, builds.pkr.hcl)│
  └───────────────────────────┬────────────────────────────┘
                              │ Boots QEMU/KVM with cloud-init
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │             Sequential Shell Provisioners              │
  │  00-base-strip.sh       -> Purge snapd, telemetry, docs│
  │  05-hypervisor-agents.sh-> QEMU agent, VMware tools    │
  │  10-network-time.sh     -> Anycast NTS chrony          │
  │  20-kernel-sysctl.sh    -> Kernel cmdline, CIS sysctls │
  │  25-baremetal-tuning.sh -> NVMe kyber, growroot, BBR   │
  │  30-36-gpu-*.sh         -> Intel / AMD / NVIDIA stacks │
  │  40-41-runtime-*.sh     -> Docker 29.8 / Podman 5.x    │
  │  50-55-k8s-*.sh         -> K8s 1.37.0 + preheat profile│
  │  60-ai-infer-*.sh       -> Hugepages, vLLM / Ollama    │
  │  99-cleanup.sh          -> Apt clean, zerofill, trim   │
  └───────────────────────────┬────────────────────────────┘
                              │
                              ▼
  ┌────────────────────────────────────────────────────────┐
  │                    Artifact Output                     │
  │  output-images/<flavor>/lusoris-cloud-<flavor>.qcow2   │
  │  Compressed: zstd -19 -T0 --sparse -> .qcow2.zst       │
  └────────────────────────────────────────────────────────┘
```

---

## 2. System Prerequisites & Installation

The build engine requires:
- **Packer** (>= 1.9.0)
- **QEMU** with KVM hardware virtualization (`qemu-system-x86_64`)
- **ShellCheck**, **shfmt**, and **yamllint** (linter suite)
- **Python 3** and **pytest** (automated verification suite)
- **zstd** (image compression)

### Installation by Operating System

#### Ubuntu / Debian (>= 24.04 / 26.04)
```bash
# Add HashiCorp official repository for Packer
curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list

# Install packages
sudo apt-get update
sudo apt-get install -y \
  packer \
  qemu-system-x86 \
  qemu-utils \
  ovmf \
  cloud-image-utils \
  shellcheck \
  yamllint \
  python3-pytest \
  zstd \
  git \
  make
```

#### Arch Linux / Manjaro
```bash
sudo pacman -S --needed \
  packer \
  qemu-base \
  qemu-img \
  edk2-ovmf \
  shellcheck \
  shfmt \
  yamllint \
  python-pytest \
  zstd \
  git \
  make
```

#### Fedora (>= 40) / RHEL / AlmaLinux
```bash
sudo dnf install -y dnf-plugins-core
sudo dnf config-manager --add-repo https://rpm.releases.hashicorp.com/fedora/hashicorp.repo

sudo dnf install -y \
  packer \
  qemu-kvm \
  qemu-img \
  edk2-ovmf \
  ShellCheck \
  yamllint \
  python3-pytest \
  zstd \
  git \
  make
```

#### macOS (Apple Silicon or Intel via Homebrew)
> [!NOTE]
> Local QEMU builds on macOS use standard QEMU without KVM acceleration, which is slower. For fast builds, Linux hosts with `/dev/kvm` access are recommended.
```bash
brew tap hashicorp/tap
brew install hashicorp/tap/packer qemu shellcheck shfmt yamllint zstd pytest git make
```

---

## 3. Hardware Acceleration Verification (KVM)

Hardware virtualization via KVM is essential for fast local builds (1–3 minutes vs 20+ minutes without KVM).

### Check KVM Availability
```bash
# Verify KVM device presence
ls -l /dev/kvm
```

### Grant User Permissions to KVM
If `/dev/kvm` is owned by `root:kvm` and your user cannot write to it:
```bash
# Add your user to the kvm group
sudo usermod -aG kvm "$USER"

# Apply group changes immediately (or log out and back in)
newgrp kvm
```

### Quick KVM Test
```bash
[ -w /dev/kvm ] && echo "KVM acceleration: Ready" || echo "Warning: KVM acceleration unavailable"
```

---

## 4. Workspace Setup & Quality Gates

### Clone the Repository
```bash
git clone https://github.com/lusoris/lusoris-cloud-images.git
cd lusoris-cloud-images
```

### The Trunk-Based Git Flow
> [!IMPORTANT]
> Direct commits to `main` are blocked. Always branch off `main`:
> ```bash
> git checkout -b feat/my-new-flavor
> ```

### Initialize Packer Plugins
Installs required Packer plugins (`packer-plugin-qemu` and `packer-plugin-proxmox`):
```bash
make init
```

### Run All Quality Gates
Before running a full image build, verify that everything passes the strict quality gates:
```bash
# 1. Format check Packer HCL files
make fmt-check

# 2. Run Packer validation, ShellCheck, and Yamllint
make lint

# 3. Run automated pytest verification suite (SSOT schema, Power of 10, zero RFC 1918 leaks)
make test
```

Expected output:
```text
==> Validating Packer configuration...
The configuration is valid.
==> Running ShellCheck on provisioner scripts...
==> Running Yamllint...
==> All lint checks passed successfully.
...
8 passed in 4.78s
```

---

## 5. Building Your First Image

Let's build `base-generic`—the minimal, zero-bloat cloud OS image.

```bash
make build-base-generic
```

### What Happens During the Build:
1. **Download**: Packer downloads the daily Ubuntu 26.04 Resolute cloud image (`resolute-server-cloudimg-amd64.img`) declared in `versions.json` to `packer/packer_cache/`.
2. **Ephemeral VM**: Packer boots QEMU with KVM, attaching the cloud image and a virtual CD-ROM labeled `cidata` containing `packer/http/meta-data` and `packer/http/user-data`.
3. **Cloud-Init Boot**: The ephemeral VM configures a temporary `ubuntu` user (`ubuntu` / `ubuntu`) and enables SSH.
4. **Provisioning**: Packer connects via SSH and executes provisioners sequentially:
   - `00-base-strip.sh`: Purges `snapd`, telemetry, unused locales, and documentation.
   - `05-hypervisor-agents.sh`: Sets up coexisting `qemu-guest-agent` and `open-vm-tools`.
   - `10-network-time.sh`: Configures chrony with Anycast NTS (`time.cloudflare.com`) and Stratum-1 servers.
   - `20-kernel-sysctl.sh`: Applies sysctls (BBR, conntrack, BPF JIT) and GRUB cmdlines.
   - `25-baremetal-tuning.sh`: Pre-stages NVMe kyber scheduling, microcode, and root auto-expansion.
   - `99-cleanup.sh`: Wipes temporary keys, apt caches, fills empty space with zeroes (`dd if=/dev/zero`), and issues `fstrim`.
5. **Output**: The VM cleanly powers down. The resulting image is placed at:
   ```text
   output-images/base-generic/lusoris-cloud-base-generic.qcow2
   ```

### Sparse Compression
Compress the image using multi-threaded zstd with sparse detection:
```bash
make compress
```
This produces `lusoris-cloud-base-generic.qcow2.zst`, reducing a ~2.5GB disk image to ~600MB.

---

## 6. Testing the Image Locally in QEMU

You can smoke-test your generated image immediately without deploying to a hypervisor:

```bash
qemu-system-x86_64 \
  -enable-kvm \
  -m 4096 \
  -smp 4 \
  -drive file=output-images/base-generic/lusoris-cloud-base-generic.qcow2,format=qcow2 \
  -net nic,model=virtio \
  -net user,hostfwd=tcp::2222-:22 \
  -nographic
```

### Connect to the VM
Open a separate terminal window and SSH into the running VM:
```bash
ssh -p 2222 -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no ubuntu@127.0.0.1
```
*(Default temporary password: `ubuntu`)*

### In-VM Verification Checklist
Run these commands inside the VM to verify image integrity:

```bash
# 1. Verify OS Release is Ubuntu 26.04 LTS (Resolute)
lsb_release -a

# 2. Verify Zero Base Bloat: Snapd must NOT exist
which snap || echo "PASS: snapd is completely absent"

# 3. Verify Telemetry is purged
systemctl status ubuntu-pro.service 2>&1 | grep "could not be found" && echo "PASS: No telemetry"

# 4. Verify Resilient Anycast NTS Time Synchronization
chronyc sources -v

# 5. Verify BBR Congestion Control is active
sysctl net.ipv4.tcp_congestion_control

# 6. Verify QEMU Guest Agent is running
systemctl is-active qemu-guest-agent

# 7. Exit and power off
sudo shutdown -h now
```

---

## 7. The 26-Flavor Selection Guide

Choose the flavor that matches your workload and hardware stack:

```text
                               Workload Tier
           ┌─────────────────────────┼─────────────────────────┐
           ▼                         ▼                         ▼
      [Base OS]                 [Containers]             [Kubernetes]
   base-generic             docker-generic            k8s-node-generic (lean)
   base-intel               docker-intel (QuickSync)  k8s-node-cilium
   base-amd                 docker-amd (ROCm 10)      k8s-node-calico
   base-nvidia-legacy       docker-nvidia (565)       k8s-node-flannel
   base-nvidia-mainstream   docker-nvidia-bleeding(615)k8s-node-intel
   base-nvidia-bleeding     podman-generic (Quadlet)  k8s-node-amd
   base-nvidia-datacenter                             k8s-node-nvidia
                                                      k8s-node-nvidia-bleeding
                                                               │
                                                               ▼
                                                        [AI Inference]
                                                       ai-infer-generic (CPU)
                                                       ai-infer-intel (Arc/Xe2)
                                                       ai-infer-amd (ROCm 10)
                                                       ai-infer-nvidia (565)
                                                       ai-infer-nvidia-bleeding(615)
```

### Build Commands Reference

| Target Category | Flavor Name | Make Command | Key Components |
| :--- | :--- | :--- | :--- |
| **Base** | `base-generic` | `make build-base-generic` | Hardened minimal OS, Anycast NTS |
| **Base** | `base-intel` | `make build-base-intel` | Intel Media (`iHD`), Level Zero, Battlemage Xe2 |
| **Base** | `base-amd` | `make build-base-amd` | AMD Mesa VA-API (`radeonsi`), RADV Vulkan |
| **Base** | `base-nvidia-legacy` | `make build-base-nvidia-legacy` | NVIDIA 535 / CUDA 12.2 (Pascal/Volta) |
| **Base** | `base-nvidia-mainstream` | `make build-base-nvidia-mainstream` | NVIDIA 565 / CUDA 12.8 (Turing/Ampere) |
| **Base** | `base-nvidia-bleeding` | `make build-base-nvidia-bleeding` | NVIDIA 615 / CUDA 13.4 (Blackwell RTX 5090) |
| **Base** | `base-nvidia-datacenter` | `make build-base-nvidia-datacenter` | NVIDIA 615 Open Modules + Fabric Manager |
| **Container** | `docker-generic` | `make build-docker-generic` | Docker CE 29.8, Docker Compose v2 |
| **Container** | `docker-intel` | `make build-docker-intel` | Docker CE + QuickSync + CDI spec |
| **Container** | `docker-amd` | `make build-docker-amd` | Docker CE + ROCm 10 + CDI spec |
| **Container** | `docker-nvidia` | `make build-docker-nvidia` | Docker CE + NVIDIA 565 + CDI spec |
| **Container** | `docker-nvidia-bleeding` | `make build-docker-nvidia-bleeding` | Docker CE + NVIDIA 615 + CDI spec |
| **Container** | `podman-generic` | `make build-podman-generic` | Rootless Podman 5.x, Quadlet, Netavark |
| **Kubernetes** | `k8s-node-generic` | `make build-k8s-generic` | K8s 1.37.0, containerd 2.3.5, lean zero-preheat |
| **Kubernetes** | `k8s-node-cilium` | `make build-k8s-cilium` | Preheated Cilium 1.20.1 & kube-vip 1.2.3 |
| **Kubernetes** | `k8s-node-calico` | `make build-k8s-calico` | Preheated Calico 3.32.2 & kube-vip 1.2.3 |
| **Kubernetes** | `k8s-node-flannel` | `make build-k8s-flannel` | Preheated Flannel 0.28.9 & kube-vip 1.2.3 |
| **Kubernetes** | `k8s-node-intel` | `make build-k8s-intel` | Intel Arc/Xe2 + Intel K8s Plugin v0.36.0 |
| **Kubernetes** | `k8s-node-amd` | `make build-k8s-amd` | AMD ROCm 10 + AMD K8s Plugin v1.37.0 |
| **Kubernetes** | `k8s-node-nvidia` | `make build-k8s-nvidia` | NVIDIA 565 + NVIDIA K8s Plugin v0.20.0 |
| **Kubernetes** | `k8s-node-nvidia-bleeding`| `make build-k8s-nvidia-bleeding` | NVIDIA 615 + NVIDIA K8s Plugin v0.20.0 |
| **AI Inference**| `ai-infer-generic` | `make build-ai-infer-generic` | AMX, AVX-512, NUMA, vLLM / Ollama CPU |
| **AI Inference**| `ai-infer-intel` | `make build-ai-infer-intel` | Intel Level Zero, OpenVINO, IPEX-LLM, CDI |
| **AI Inference**| `ai-infer-amd` | `make build-ai-infer-amd` | AMD ROCm 10, /dev/kfd, RDNA 3/4 & Instinct |
| **AI Inference**| `ai-infer-nvidia` | `make build-ai-infer-nvidia` | NVIDIA 565, Hugepages, vLLM / Ollama |
| **AI Inference**| `ai-infer-nvidia-bleeding`| `make build-ai-infer-nvidia-bleeding` | NVIDIA 615, Blackwell RTX 5090 / B200, vLLM |


---

## 8. Hypervisor & Bare-Metal Deployment

### Proxmox VE (Direct Packer Template)
Create a `proxmox.pkrvars.hcl` file (gitignored by default):

```hcl
proxmox_url         = "https://pve.example.com:8006/api2/json"
proxmox_token_id    = "packer@pve!packer-token"
proxmox_token_secret= "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
proxmox_node        = "pve-node-01"
storage_pool        = "local-zfs"
vm_id               = 9000
```

Build the template directly into Proxmox:
```bash
cd packer
packer build -var-file=../proxmox.pkrvars.hcl -only="base-generic.proxmox-clone.template" .
```

### Proxmox VE (Manual QCOW2 Import)
If you built `.qcow2` locally with QEMU and want to import it manually to Proxmox:
```bash
# Upload image to Proxmox host, then run on PVE shell:
qm create 9001 --name lusoris-base-generic --memory 4096 --cores 4 --net0 virtio,bridge=vmbr0
qm importdisk 9001 output-images/base-generic/lusoris-cloud-base-generic.qcow2 local-zfs
qm set 9001 --scsihw virtio-scsi-pci --virtio0 local-zfs:vm-9001-disk-0
qm set 9001 --boot c --bootdisk virtio0
qm set 9001 --serial0 socket --vga serial0
qm set 9001 --agent enabled=1
qm template 9001
```

### Unraid
1. Copy the `.qcow2` image to your Unraid domains share:
   ```bash
   scp output-images/docker-generic/lusoris-cloud-docker-generic.qcow2 root@tower.example.com:/mnt/user/domains/lusoris-docker/vdisk1.qcow2
   ```
2. In Unraid VM Manager:
   - Primary vDisk: `/mnt/user/domains/lusoris-docker/vdisk1.qcow2`
   - Primary vDisk Bus: `VirtIO`
   - Network Model: `virtio-net`
   - VirtFS host sharing (`9p` or `virtiofs`) is pre-supported.

### VMware ESXi
Convert the `.qcow2` image to stream-optimized `.vmdk`:
```bash
qemu-img convert -O vmdk -o subformat=streamOptimized \
  output-images/base-generic/lusoris-cloud-base-generic.qcow2 \
  lusoris-cloud-base-generic.vmdk
```
Deploy via `ovftool` or upload via ESXi Datastore Browser.

### Bare-Metal Streaming Direct to NVMe
Flash the compressed `.raw.zst` directly to physical NVMe or SATA storage from a live USB:
```bash
curl -fsSL https://releases.lusoris.org/lusoris-base-generic.raw.zst | \
  zstdcat | sudo dd of=/dev/nvme0n1 bs=4M status=progress conv=fsync
```
On first boot, `25-baremetal-tuning.sh` automatically expands the root partition to fill the physical disk via `growpart`.

---

## 9. Developer & Contributor Guide

### 1. Single Source of Truth (`versions.json`)
Never hardcode versions, package URLs, or image tags in shell scripts or Packer files.
- To upgrade Kubernetes or a driver: edit [`versions.json`](versions.json).
- Packer reads `versions.json` dynamically via `jsondecode()` in [`packer/builds.pkr.hcl`](packer/builds.pkr.hcl).
- Injected into provisioners via environment variables (`DISTRO_RELEASE`, `K8S_VERSION`, etc.).

### 2. NASA/JPL Power of 10 Bash Invariants
All shell scripts under `packer/provisioners/` must follow strict safety rules:
- Every function must be **<= 60 lines**.
- Enforce `set -euo pipefail`.
- Always check command return codes.
- Zero warnings from `shellcheck` (`shellcheck packer/provisioners/*.sh`).
- Zero formatting diffs from `shfmt` (`shfmt -d -i 2 -ci packer/provisioners/*.sh`).

### 3. Zero-Leak Invariant
Never commit:
- RFC 1918 private IP addresses (`10.x`, `192.168.x`, `172.16-31.x`). Use standard documentation placeholders (`pve.example.com`, `192.0.2.x`, `198.51.100.x`).
- Local user home paths (`/home/username`). Use generic paths (`/tmp`, `/etc`).
Automated tests in `tests/test_config.py` enforce this on every `make test`.

### 4. Docs & Code Synchrony
Any change to a flavor, environment variable, or provisioner step must be updated in documentation (`README.md`, `ONBOARDING.md`, and `docs/`) in the **exact same commit**.

### 5. Git Commit & Pull Request Flow
```bash
# 1. Create a descriptive branch
git checkout -b feat/add-new-capability

# 2. Make your edits and run quality gates
make lint
make test

# 3. Commit using Conventional Commits
git commit -m "feat(provisioners): add custom telemetry monitor"

# 4. Push and open a PR
git push origin feat/add-new-capability
gh pr create --fill
```

---

## 10. Troubleshooting & FAQ

### Q: `qemu: cannot access /dev/kvm: Permission denied`
**Fix**: Add your user to the `kvm` group:
```bash
sudo usermod -aG kvm $USER
newgrp kvm
```

### Q: Packer build fails with `SSH handshake failed / timeout`
**Causes & Fixes**:
1. **KVM unavailable**: Without KVM, cloud-init takes longer than the 15-minute timeout. Ensure `/dev/kvm` is writable.
2. **CPU/RAM starvation**: Ensure your machine has at least 4GB free RAM. You can override build resources:
   ```bash
   cd packer && packer build -var="memory=2048" -var="cpus=2" -only="base-generic.qemu.image" .
   ```
3. **Corrupted Packer Cache**: If the upstream ISO download was interrupted:
   ```bash
   make clean
   rm -rf packer/packer_cache/
   ```

### Q: `make lint` fails on ShellCheck
**Fix**: Run `shellcheck packer/provisioners/<failing-script>.sh` to locate the line and fix the warning (e.g., quote variables, avoid `eval`, check exit codes).

### Q: `make test` fails with `RFC 1918 leak detected`
**Fix**: Search the repository for private IPs:
```bash
grep -rnE "192\.168|10\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\." .
```
Replace any matches with documentation IP ranges (`192.0.2.x`, `198.51.100.x`, `203.0.113.x`).

---

## 11. Useful Makefile Commands

```bash
make help               # Display all available targets with descriptions
make init               # Initialize Packer plugins (QEMU & Proxmox)
make fmt                # Format Packer HCL configurations
make fmt-check          # Verify Packer HCL formatting
make lint               # Run packer validate, shellcheck, and yamllint
make test               # Run automated pytest verification suite
make compress           # Compress output images with multi-threaded sparse zstd
make clean              # Clean local build outputs and caches
make docs-serve         # Run local documentation portal (MkDocs)
```
