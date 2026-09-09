# builds.pkr.hcl — Target Flavor Matrix Definitions
# Dynamically ingests Single Source of Truth versions from ../versions.json

locals {
  manifest = jsondecode(file("${path.root}/../versions.json"))

  k8s_major_minor          = local.manifest.kubernetes.major_minor
  k8s_version              = local.manifest.kubernetes.version
  img_pause                = local.manifest.kubernetes.images.pause
  img_coredns              = local.manifest.kubernetes.images.coredns
  img_cilium               = local.manifest.kubernetes.images.cilium
  img_kube_vip             = local.manifest.kubernetes.images.kube_vip
  img_node_exporter        = local.manifest.kubernetes.images.node_exporter
  img_intel_plugin         = local.manifest.drivers.intel.k8s_plugin
  img_amd_plugin           = local.manifest.drivers.amd.k8s_plugin
  img_nvidia_plugin        = local.manifest.drivers.nvidia.k8s_plugin
  nvidia_legacy_driver     = local.manifest.drivers.nvidia.legacy_driver
  nvidia_mainstream_driver = local.manifest.drivers.nvidia.mainstream_driver
  nvidia_datacenter_driver = local.manifest.drivers.nvidia.datacenter_driver
  rocm_version             = local.manifest.drivers.amd.rocm_version

  common_env = [
    "K8S_MAJOR_MINOR=${local.k8s_major_minor}",
    "K8S_VERSION=${local.k8s_version}",
    "IMG_PAUSE=${local.img_pause}",
    "IMG_COREDNS=${local.img_coredns}",
    "IMG_CILIUM=${local.img_cilium}",
    "IMG_KUBE_VIP=${local.img_kube_vip}",
    "IMG_NODE_EXPORTER=${local.img_node_exporter}",
    "IMG_INTEL_PLUGIN=${local.img_intel_plugin}",
    "IMG_AMD_PLUGIN=${local.img_amd_plugin}",
    "IMG_NVIDIA_PLUGIN=${local.img_nvidia_plugin}",
    "NVIDIA_LEGACY_DRIVER=${local.nvidia_legacy_driver}",
    "NVIDIA_MAINSTREAM_DRIVER=${local.nvidia_mainstream_driver}",
    "NVIDIA_DATACENTER_BRANCH=${local.nvidia_datacenter_driver}",
    "ROCM_VERSION=${local.rocm_version}"
  ]
}

# 1. Base Generic: Minimal hardened cloud & VM base
build {
  name    = "base-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-generic", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 2. Base Intel: Hardened cloud image with Intel Xe/i915 GPU acceleration
build {
  name    = "base-intel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-intel", "BM_GEN=intel"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
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
    environment_vars = concat(["FLAVOR=base-amd", "BM_GEN=amd"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/31-gpu-amd-mesa.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 4. Base NVIDIA Legacy: Pascal & Volta (CUDA 12.2 / Driver 535)
build {
  name    = "base-nvidia-legacy"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-nvidia-legacy", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/33-gpu-nvidia-legacy.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 5. Base NVIDIA Mainstream: Turing, Ampere, Ada (CUDA 12.8 / Driver 565)
build {
  name    = "base-nvidia-mainstream"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-nvidia-mainstream", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/34-gpu-nvidia-mainstream.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 6. Base NVIDIA Datacenter: Hopper & Blackwell (Open Modules + Fabric Manager)
build {
  name    = "base-nvidia-datacenter"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-nvidia-datacenter", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/35-gpu-nvidia-datacenter.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 7. Docker Generic: Hardened Docker CE + Compose appliance
build {
  name    = "docker-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=docker-generic", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 8. Docker Intel: Docker CE with Intel QuickSync & Level Zero
build {
  name    = "docker-intel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=docker-intel", "BM_GEN=intel"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/30-gpu-intel.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 9. Docker AMD: Docker CE with AMD ROCm 6.x compute runtime
build {
  name    = "docker-amd"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=docker-amd", "BM_GEN=amd"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/32-gpu-amd-rocm.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 10. Docker NVIDIA: Docker CE with NVIDIA Container Toolkit & CDI
build {
  name    = "docker-nvidia"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=docker-nvidia", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/34-gpu-nvidia-mainstream.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 11. Podman Generic: Rootless Podman 5.x with Quadlet systemd support
build {
  name    = "podman-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=podman-generic", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/41-podman-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 12. Kubernetes Node Generic: Worker node with pre-cached Cilium and kube-vip
build {
  name    = "k8s-node-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-generic", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/50-k8s-runtime.sh",
      "${path.root}/provisioners/55-k8s-precache.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 13. Kubernetes Node Intel: Worker node with Intel GPU drivers & Device Plugin
build {
  name    = "k8s-node-intel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-intel", "BM_GEN=intel"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/30-gpu-intel.sh",
      "${path.root}/provisioners/50-k8s-runtime.sh",
      "${path.root}/provisioners/55-k8s-precache.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 14. Kubernetes Node AMD: Worker node with AMD ROCm & AMD Device Plugin
build {
  name    = "k8s-node-amd"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-amd", "BM_GEN=amd"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/32-gpu-amd-rocm.sh",
      "${path.root}/provisioners/50-k8s-runtime.sh",
      "${path.root}/provisioners/55-k8s-precache.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 15. Kubernetes Node NVIDIA: Worker node with NVIDIA toolkit & NVIDIA Device Plugin
build {
  name    = "k8s-node-nvidia"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-nvidia", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/34-gpu-nvidia-mainstream.sh",
      "${path.root}/provisioners/50-k8s-runtime.sh",
      "${path.root}/provisioners/55-k8s-precache.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 16. AI Inference NVIDIA: Tuned vLLM / Ollama node with hugepages and CUDA
build {
  name    = "ai-infer-nvidia"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=ai-infer-nvidia", "BM_GEN=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/34-gpu-nvidia-mainstream.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/60-ai-infer-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}
