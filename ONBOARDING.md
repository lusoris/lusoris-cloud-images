# Onboarding Guide: lusoris-cloud-images

> Welcome to `lusoris-cloud-images`! This guide walks you through setting up your environment, validating quality gates, and building flavored cloud images across our 4D matrix.

---

## 1. Quickstart Workspace Setup

Clone and open the repository:

```bash
git clone https://github.com/lusoris/lusoris-cloud-images.git
cd lusoris-cloud-images
code .
```

Or launch Antigravity directly in the directory:
```bash
cd lusoris-cloud-images
agy
```

---

## 2. Local Environment Check

The builder requires `packer`, `qemu-system-x86_64` (with KVM acceleration), `shellcheck`, and `pytest`.

Run the pre-flight check:
```bash
packer version
qemu-system-x86_64 --version
shellcheck --version
pytest --version

# Check KVM access
[ -w /dev/kvm ] && echo "KVM acceleration: Available" || echo "Warning: KVM acceleration unavailable, will be slow"
```

---

## 3. Verify Quality Gates

Before running image builds, execute our verification suite:

```bash
# Initialize Packer plugins (installs QEMU and Proxmox plugins)
make init

# Run linting (Packer validate, ShellCheck, Yamllint)
make lint

# Run automated tests
make test
```

---

## 4. Build Your First Image

All builds read upstream versions declaratively from [`versions.json`](versions.json).

### Base Cloud Image (Generic)
```bash
make build-base-generic
```
Builds a minimal hardened `.qcow2` image to `output-images/base-generic/`.

### Docker & Container Appliances
```bash
# Standalone Docker CE + Compose host
make build-docker-generic

# Docker CE with NVIDIA Container Toolkit & CDI
make build-docker-nvidia
```

### Kubernetes Node Images
```bash
# Kubernetes worker node with lean footprint (zero-preheat)
make build-k8s-generic

# Kubernetes worker node with preheated Cilium and kube-vip
make build-k8s-cilium

# Kubernetes worker node with Blackwell GPU (RTX 5090 / B200)
make build-k8s-nvidia-bleeding
```

---

## 5. Testing the Built Image Locally in QEMU

Smoke-test your generated `.qcow2` image directly with headless QEMU:

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

---

## 6. Hypervisor Deployment Paths

### Proxmox VE
Deploy templates directly via the Proxmox builder:
```bash
cd packer
packer build -var-file=../proxmox.pkrvars.hcl -only="base-generic.proxmox-clone.template" .
```

### Unraid
Copy the generated `.qcow2` to `/mnt/user/domains/<vm-name>/vdisk1.qcow2` and select VirtIO disk/net. Guest agent IP reporting and Unraid `virtiofs` host share passthrough are enabled out of the box.

### Bare-Metal Direct Flash
Flash compressed `.raw.zst` directly to NVMe/SATA storage:
```bash
curl -fsSL https://releases.lusoris.org/lusoris-base-generic.raw.zst | \
  zstdcat | sudo dd of=/dev/nvme0n1 bs=4M status=progress conv=fsync
```

---

## 7. Documentation Portal

Run the full documentation portal locally:
```bash
make docs-serve
```
And view the docs in your browser at `http://127.0.0.1:8000`.
