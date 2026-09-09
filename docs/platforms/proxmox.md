# Proxmox VE Deployment Guide

`lusoris-cloud-images` natively supports Proxmox VE via automated template cloning or direct `.qcow2` import.

## Direct Import via CLI (`qm importdisk`)

```bash
# 1. Download and decompress the desired release image
curl -fsSL https://github.com/lusoris/lusoris-cloud-images/releases/latest/download/lusoris-cloud-docker-generic.qcow2.zst | zstdcat > /tmp/image.qcow2

# 2. Create a VM shell (ID: 9000)
qm create 9000 --name "lusoris-docker-template" --memory 4096 --cores 4 --net0 virtio,bridge=vmbr0

# 3. Import disk into Proxmox storage (e.g. local-lvm)
qm importdisk 9000 /tmp/image.qcow2 local-lvm

# 4. Attach disk, configure cloud-init, and set boot order
qm set 9000 --scsihw virtio-scsi-pci --scsi0 local-lvm:vm-9000-disk-0,discard=on,ssd=1
qm set 9000 --ide2 local-lvm:cloudinit
qm set 9000 --boot c --bootdisk scsi0
qm set 9000 --serial0 socket --vga serial0
qm set 9000 --agent enabled=1

# 5. Convert to template
qm template 9000
rm -f /tmp/image.qcow2
```

## Automated Packer Proxmox Clone

Define a `proxmox.pkrvars.hcl` file:
```hcl
proxmox_url          = "https://pve.example.com:8006/api2/json"
proxmox_token_id     = "packer@pve!automation"
proxmox_token_secret = "YOUR_TOKEN_SECRET"
proxmox_node         = "pve01"
storage_pool         = "local-lvm"
vm_id                = 9000
```

Build directly to Proxmox:
```bash
cd packer
packer build -var-file=proxmox.pkrvars.hcl -only="base-intel.proxmox-clone.template" .
```
