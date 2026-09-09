# builds.pkr.hcl — Target Flavor Matrix Definitions

# 1. Base Generic: Minimal hardened cloud & VM base
build {
  name    = "base-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = ["FLAVOR=base-generic"]
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/10-network-ptb.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 2. Base Intel: Hardened cloud image with Intel Xe/i915 GPU acceleration
build {
  name    = "base-intel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = ["FLAVOR=base-intel"]
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/10-network-ptb.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/30-gpu-intel.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 3. Base AMD: Hardened cloud image with AMD Radeon / APU acceleration
build {
  name    = "base-amd"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = ["FLAVOR=base-amd"]
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/10-network-ptb.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/31-gpu-amd.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 4. Base NVIDIA: Hardened cloud image with NVIDIA Container Toolkit
build {
  name    = "base-nvidia"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = ["FLAVOR=base-nvidia"]
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/10-network-ptb.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/32-gpu-nvidia.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 5. Kubernetes Node Generic: Worker/CP with pre-baked containerd, kubelet, and daemonsets
build {
  name    = "k8s-node-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = ["FLAVOR=k8s-node-generic"]
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/10-network-ptb.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/40-k8s-runtime.sh",
      "${path.root}/provisioners/45-k8s-precache.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 6. Kubernetes Node Intel: Worker with Intel GPU drivers & Intel K8s Device Plugin
build {
  name    = "k8s-node-intel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = ["FLAVOR=k8s-node-intel"]
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/10-network-ptb.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/30-gpu-intel.sh",
      "${path.root}/provisioners/40-k8s-runtime.sh",
      "${path.root}/provisioners/45-k8s-precache.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 7. Kubernetes Node AMD: Worker with AMD GPU drivers & AMD K8s Device Plugin
build {
  name    = "k8s-node-amd"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = ["FLAVOR=k8s-node-amd"]
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/10-network-ptb.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/31-gpu-amd.sh",
      "${path.root}/provisioners/40-k8s-runtime.sh",
      "${path.root}/provisioners/45-k8s-precache.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 8. Kubernetes Node NVIDIA: Worker with NVIDIA drivers & NVIDIA K8s Device Plugin
build {
  name    = "k8s-node-nvidia"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = ["FLAVOR=k8s-node-nvidia"]
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/10-network-ptb.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/32-gpu-nvidia.sh",
      "${path.root}/provisioners/40-k8s-runtime.sh",
      "${path.root}/provisioners/45-k8s-precache.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}
