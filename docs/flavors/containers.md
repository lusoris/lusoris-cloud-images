# Container Appliance Flavors

`lusoris-cloud-images` provides pre-configured, production-grade container host appliances supporting both **Docker CE** and **Rootless Podman 5.x**.

## Docker Appliances (`docker-*`)

Pre-baked with official Docker CE, `containerd.io`, and Docker Compose v2 plugin.

### Daemon Tuning (`/etc/docker/daemon.json`)
```json
{
  "exec-opts": ["native.cgroupdriver=systemd"],
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "50m",
    "max-file": "3"
  },
  "live-restore": true
}
```

### Flavors
- **`docker-generic`**: Standard CPU container host for Docker Compose stacks.
- **`docker-intel`**: Pre-configured Intel QuickSync and Level Zero access for Jellyfin, Plex, and Intel OpenVINO containers.
- **`docker-amd`**: Pre-configured AMD ROCm 6.x runtime and `/dev/kfd` access for PyTorch and ROCm containers.
- **`docker-nvidia`**: Pre-configured NVIDIA Container Toolkit and CDI v0.6+ specifications for GPU-accelerated Docker containers.

---

## Podman Appliances (`podman-generic`)

Daemonless and rootless container host designed for security-conscious environments and systemd integration via **Quadlet**.

### Features
- Rootless subordinate UID/GID mappings pre-configured (`/etc/subuid` and `/etc/subgid`).
- Quadlet generator directories initialized at `/etc/containers/systemd/` and `~/.config/containers/systemd/`.
- Includes `podman`, `buildah`, `skopeo`, and `crun`.
