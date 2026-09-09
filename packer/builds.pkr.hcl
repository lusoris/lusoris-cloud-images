# builds.pkr.hcl — Target Flavor Matrix Definitions
# Dynamically ingests Single Source of Truth versions from ../versions.json

locals {
  manifest = jsondecode(file("${path.root}/../versions.json"))

  distro_release           = local.manifest.distro.release
  k8s_major_minor          = local.manifest.kubernetes.major_minor
  k8s_version              = local.manifest.kubernetes.version
  img_pause                = local.manifest.kubernetes.images.pause
  img_coredns              = local.manifest.kubernetes.images.coredns
  img_cilium               = local.manifest.kubernetes.images.cilium
  img_cilium_operator      = local.manifest.kubernetes.images.cilium_operator
  img_kube_vip             = local.manifest.kubernetes.images.kube_vip
  img_node_exporter        = local.manifest.kubernetes.images.node_exporter
  img_calico_cni           = local.manifest.kubernetes.images.calico_cni
  img_calico_node          = local.manifest.kubernetes.images.calico_node
  img_calico_ctrl          = local.manifest.kubernetes.images.calico_controllers
  img_flannel              = local.manifest.kubernetes.images.flannel
  img_flannel_cni          = local.manifest.kubernetes.images.flannel_cni
  img_intel_plugin         = local.manifest.drivers.intel.k8s_plugin
  img_amd_plugin           = local.manifest.drivers.amd.k8s_plugin
  img_nvidia_plugin        = local.manifest.drivers.nvidia.k8s_plugin
  nvidia_legacy_driver     = local.manifest.drivers.nvidia.legacy_driver
  nvidia_mainstream_driver = local.manifest.drivers.nvidia.mainstream_driver
  nvidia_modern_driver     = local.manifest.drivers.nvidia.modern_driver
  nvidia_bleeding_driver   = local.manifest.drivers.nvidia.bleeding_driver
  nvidia_datacenter_driver = local.manifest.drivers.nvidia.datacenter_driver
  cuda_legacy              = local.manifest.drivers.nvidia.cuda_legacy
  cuda_mainstream          = local.manifest.drivers.nvidia.cuda_mainstream
  cuda_modern              = local.manifest.drivers.nvidia.cuda_modern
  cuda_bleeding            = local.manifest.drivers.nvidia.cuda_bleeding
  rocm_legacy_version      = local.manifest.drivers.amd.rocm_legacy_version
  rocm_bleeding_version    = local.manifest.drivers.amd.rocm_bleeding_version

  common_env = [
    "DISTRO_RELEASE=${local.distro_release}",
    "K8S_MAJOR_MINOR=${local.k8s_major_minor}",
    "K8S_VERSION=${local.k8s_version}",
    "IMG_PAUSE=${local.img_pause}",
    "IMG_COREDNS=${local.img_coredns}",
    "IMG_CILIUM=${local.img_cilium}",
    "IMG_CILIUM_OPERATOR=${local.img_cilium_operator}",
    "IMG_CALICO_CNI=${local.img_calico_cni}",
    "IMG_CALICO_NODE=${local.img_calico_node}",
    "IMG_CALICO_CTRL=${local.img_calico_ctrl}",
    "IMG_FLANNEL=${local.img_flannel}",
    "IMG_FLANNEL_CNI=${local.img_flannel_cni}",
    "IMG_KUBE_VIP=${local.img_kube_vip}",
    "IMG_NODE_EXPORTER=${local.img_node_exporter}",
    "IMG_INTEL_PLUGIN=${local.img_intel_plugin}",
    "IMG_AMD_PLUGIN=${local.img_amd_plugin}",
    "IMG_NVIDIA_PLUGIN=${local.img_nvidia_plugin}",
    "NVIDIA_LEGACY_DRIVER=${local.nvidia_legacy_driver}",
    "NVIDIA_MAINSTREAM_DRIVER=${local.nvidia_mainstream_driver}",
    "NVIDIA_MODERN_DRIVER=${local.nvidia_modern_driver}",
    "NVIDIA_BLEEDING_DRIVER=${local.nvidia_bleeding_driver}",
    "NVIDIA_DATACENTER_BRANCH=${local.nvidia_datacenter_driver}",
    "CUDA_LEGACY=${local.cuda_legacy}",
    "CUDA_MAINSTREAM=${local.cuda_mainstream}",
    "CUDA_MODERN=${local.cuda_modern}",
    "CUDA_BLEEDING=${local.cuda_bleeding}",
    "ROCM_VERSION=${local.rocm_bleeding_version}",
    "ROCM_LEGACY_VERSION=${local.rocm_legacy_version}"
  ]
}

# 1. Base Generic: Minimal hardened cloud & VM base
build {
  name    = "base-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-generic", "BM_GEN=generic", "KERNEL_PROFILE=generic"], local.common_env)
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

# 2. Base Intel: Hardened cloud image with Intel Xe/Arc GPU acceleration
build {
  name    = "base-intel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-intel", "BM_GEN=intel", "KERNEL_PROFILE=generic"], local.common_env)
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

# 3. Base AMD: AMD Mesa VA-API and RADV Vulkan runtime
build {
  name    = "base-amd"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-amd", "BM_GEN=amd", "KERNEL_PROFILE=generic"], local.common_env)
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

# 4. Base NVIDIA Legacy: NVIDIA 535 LTSB for Pascal and Volta
build {
  name    = "base-nvidia-legacy"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-nvidia-legacy", "BM_GEN=generic", "KERNEL_PROFILE=generic"], local.common_env)
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

# 5. Base NVIDIA Mainstream: NVIDIA 565 for Turing, Ampere, and Ada
build {
  name    = "base-nvidia-mainstream"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-nvidia-mainstream", "BM_GEN=generic", "KERNEL_PROFILE=generic"], local.common_env)
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

# 6. Base NVIDIA Bleeding: NVIDIA R615 / CUDA 13.4 for Blackwell RTX 5090 & B200
build {
  name    = "base-nvidia-bleeding"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-nvidia-bleeding", "BM_GEN=generic", "KERNEL_PROFILE=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/36-gpu-nvidia-bleeding.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 7. Base NVIDIA Datacenter: NVIDIA 615 Open Kernel Modules + Fabric Manager
build {
  name    = "base-nvidia-datacenter"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=base-nvidia-datacenter", "BM_GEN=generic", "KERNEL_PROFILE=generic"], local.common_env)
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

# 8. Docker Generic: Docker CE 29.8 + Compose v2
build {
  name    = "docker-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=docker-generic", "BM_GEN=generic", "KERNEL_PROFILE=generic"], local.common_env)
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

# 9. Docker Intel: Docker CE + Intel QuickSync & Level Zero
build {
  name    = "docker-intel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=docker-intel", "BM_GEN=intel", "KERNEL_PROFILE=generic"], local.common_env)
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

# 10. Docker AMD: Docker CE + AMD ROCm 10 Compute Stack
build {
  name    = "docker-amd"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=docker-amd", "BM_GEN=amd", "KERNEL_PROFILE=generic"], local.common_env)
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

# 11. Docker NVIDIA Mainstream: Docker CE + NVIDIA Container Toolkit
build {
  name    = "docker-nvidia"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=docker-nvidia", "BM_GEN=generic", "KERNEL_PROFILE=generic"], local.common_env)
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

# 12. Docker NVIDIA Bleeding: Docker CE + NVIDIA R615 / CUDA 13.4
build {
  name    = "docker-nvidia-bleeding"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=docker-nvidia-bleeding", "BM_GEN=generic", "KERNEL_PROFILE=generic"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/36-gpu-nvidia-bleeding.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 13. Podman Generic: Rootless Podman 5.x + Netavark + Quadlet
build {
  name    = "podman-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=podman-generic", "BM_GEN=generic", "KERNEL_PROFILE=generic"], local.common_env)
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

# 14. K8s Node Generic (Lean): containerd 2.3.5, kubelet, zero preheat (~1.2GB)
build {
  name    = "k8s-node-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-generic", "PREHEAT_PROFILE=lean", "KERNEL_PROFILE=k8s"], local.common_env)
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

# 15. K8s Node Cilium: Preheated Cilium 1.20 + kube-vip 1.2.3
build {
  name    = "k8s-node-cilium"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-cilium", "PREHEAT_PROFILE=cilium", "KERNEL_PROFILE=k8s"], local.common_env)
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

# 16. K8s Node Calico: Preheated Calico 3.32 + kube-vip 1.2.3
build {
  name    = "k8s-node-calico"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-calico", "PREHEAT_PROFILE=calico", "KERNEL_PROFILE=k8s"], local.common_env)
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

# 17. K8s Node Flannel: Preheated Flannel 0.28 + kube-vip 1.2.3
build {
  name    = "k8s-node-flannel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-flannel", "PREHEAT_PROFILE=flannel", "KERNEL_PROFILE=k8s"], local.common_env)
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

# 18. K8s Node Intel: Intel GPU drivers + Intel Device Plugin v0.36
build {
  name    = "k8s-node-intel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-intel", "BM_GEN=intel", "PREHEAT_PROFILE=lean", "KERNEL_PROFILE=k8s"], local.common_env)
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

# 19. K8s Node AMD: AMD ROCm 10 + AMD Device Plugin v1.37
build {
  name    = "k8s-node-amd"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-amd", "BM_GEN=amd", "PREHEAT_PROFILE=lean", "KERNEL_PROFILE=k8s"], local.common_env)
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

# 20. K8s Node NVIDIA Mainstream: NVIDIA 565/595 + Device Plugin v0.20
build {
  name    = "k8s-node-nvidia"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-nvidia", "BM_GEN=generic", "PREHEAT_PROFILE=lean", "KERNEL_PROFILE=k8s"], local.common_env)
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

# 21. K8s Node NVIDIA Bleeding: NVIDIA R615 / CUDA 13.4 + Device Plugin v0.20
build {
  name    = "k8s-node-nvidia-bleeding"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=k8s-node-nvidia-bleeding", "BM_GEN=generic", "PREHEAT_PROFILE=lean", "KERNEL_PROFILE=k8s"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/36-gpu-nvidia-bleeding.sh",
      "${path.root}/provisioners/50-k8s-runtime.sh",
      "${path.root}/provisioners/55-k8s-precache.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 22. AI Infer Generic: CPU High-Throughput Inference (AMX, AVX-512, NUMA, vLLM/Ollama CPU)
build {
  name    = "ai-infer-generic"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=ai-infer-generic", "BM_GEN=generic", "KERNEL_PROFILE=ai-infer"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/60-ai-infer-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 23. AI Infer Intel: Intel Arc/Battlemage Xe2 + OpenVINO / IPEX-LLM + Level Zero CDI
build {
  name    = "ai-infer-intel"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=ai-infer-intel", "BM_GEN=intel", "KERNEL_PROFILE=ai-infer"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/30-gpu-intel.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/60-ai-infer-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 24. AI Infer AMD: AMD ROCm 10 + RDNA3/4 & Instinct MI300 + /dev/kfd CDI
build {
  name    = "ai-infer-amd"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=ai-infer-amd", "BM_GEN=amd", "KERNEL_PROFILE=ai-infer"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/32-gpu-amd-rocm.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/60-ai-infer-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

# 25. AI Infer NVIDIA Mainstream: NVIDIA 565 + THP always + vLLM/Ollama
build {
  name    = "ai-infer-nvidia"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=ai-infer-nvidia", "BM_GEN=generic", "KERNEL_PROFILE=ai-infer"], local.common_env)
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

# 26. AI Infer NVIDIA Bleeding: NVIDIA R615 / CUDA 13.4 + Blackwell RTX 5090 / B200 + THP
build {
  name    = "ai-infer-nvidia-bleeding"
  sources = ["source.qemu.image", "source.proxmox-clone.template"]

  provisioner "shell" {
    environment_vars = concat(["FLAVOR=ai-infer-nvidia-bleeding", "BM_GEN=generic", "KERNEL_PROFILE=ai-infer"], local.common_env)
    scripts = [
      "${path.root}/provisioners/00-base-strip.sh",
      "${path.root}/provisioners/05-hypervisor-agents.sh",
      "${path.root}/provisioners/10-network-time.sh",
      "${path.root}/provisioners/20-kernel-sysctl.sh",
      "${path.root}/provisioners/25-baremetal-tuning.sh",
      "${path.root}/provisioners/36-gpu-nvidia-bleeding.sh",
      "${path.root}/provisioners/40-docker-runtime.sh",
      "${path.root}/provisioners/60-ai-infer-runtime.sh",
      "${path.root}/provisioners/99-cleanup.sh"
    ]
  }
}

