# Onboarding Guide: lusoris-cloud-images

> Welcome to `lusoris-cloud-images`! This guide walks you through switching your editor workspace root, validating your local environment, and building your first flavored cloud image.

---

## 1. Switching Project Roots

To open and work on this repository directly:

### VS Code / Cursor / Windsurf
```bash
git clone https://github.com/lusoris/lusoris-cloud-images.git
cd lusoris-cloud-images
code .
```
Or open the cloned folder via **File -> Open Folder...**.

### Antigravity / Agent CLI
Launch Antigravity or any autonomous agent directly in the project directory:
```bash
cd lusoris-cloud-images
agy
```

---

## 2. Local Environment Check

The builder requires `packer`, `qemu-system-x86_64` (with KVM acceleration), and development linters.

Run the pre-flight check:
```bash
# Check CLI versions
packer version
qemu-system-x86_64 --version
shellcheck --version
pytest --version

# Check KVM access
[ -w /dev/kvm ] && echo "KVM acceleration: Available" || echo "Warning: KVM acceleration unavailable, will be slow"
```

---

## 3. Verify Quality Gates

Before running image builds, execute the verification suite:

```bash
# Initialize Packer plugins (installs QEMU and Proxmox plugins)
make init

# Run linting (Packer validate, ShellCheck, Yamllint)
make lint

# Run automated tests
make test
```

Expected output:
```text
==> Validating Packer configuration...
The configuration is valid.
==> Running ShellCheck on provisioner scripts...
==> All lint checks passed successfully.
====== 5 passed in 0.25s ======
```

---

## 4. Build Your First Image

### Standalone QEMU Build (Base Generic)
To build a lean base cloud image (`.qcow2`) locally:

```bash
make build-generic
```

This will:
1. Download the official Ubuntu 26.04 Resolute LTS cloud image.
2. Launch a headless QEMU VM with cloud-init seed data.
3. Execute `00-base-strip.sh`, `10-network-ptb.sh`, and `20-kernel-sysctl.sh`.
4. Run `99-cleanup.sh` and trim free space.
5. Save the output to `output-images/base-generic/lusoris-cloud-base-generic.qcow2`.

### Building GPU-Accelerated Flavors
```bash
# Intel Arc / Flex / iGPU
make build-intel

# AMD Radeon / APU
make build-amd

# NVIDIA Container Toolkit
make build-nvidia
```

### Building Kubernetes Node Images
```bash
# Kubernetes worker with pre-cached Cilium, kube-vip, and containerd
make build-k8s-generic

# Kubernetes worker with Intel GPU pass-through & Intel Device Plugin
make build-k8s-intel
```

---

## 5. Testing the Built Image Locally

You can launch the generated `.qcow2` image directly in QEMU for instant smoke testing:

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

Then SSH into the running instance in another terminal:
```bash
ssh -p 2222 ubuntu@localhost
```

---

## 6. Proxmox VE Deployment (Optional)

To deploy templates directly to your Proxmox cluster:

1. Create a `proxmox.pkrvars.hcl` file (git-ignored):
   ```hcl
   proxmox_url          = "https://pve.example.com:8006/api2/json"
   proxmox_token_id     = "terraform@pve!terraform"
   proxmox_token_secret = "YOUR_TOKEN_SECRET"
   proxmox_node         = "pve01"
   storage_pool         = "local-lvm"
   vm_id                = 9000
   ```
2. Run Packer with the Proxmox target:
   ```bash
   cd packer
   packer build -var-file=../proxmox.pkrvars.hcl -only="base-intel.proxmox-clone.template" .
   ```

---

## 7. Next Steps & Roadmap

- [ ] Add Bare-Metal (BM) ISO and raw disk builder for network PXE/iPXE installs.
- [ ] Connect GitHub Actions matrix builds to automate monthly `.qcow2` releases.
- [ ] Integrate with `lusoris/k8s` cluster GitOps for automated node provisioning.
