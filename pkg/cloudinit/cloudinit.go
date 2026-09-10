// Copyright 2026 Lusoris
// Package cloudinit generates hardened cloud-init user-data and meta-data
// across virtualization platforms and developer workstations.
package cloudinit

import (
	"fmt"
	"strings"
)

// Config specifies the runtime identity and platform targets for cloud-init generation.
type Config struct {
	Hostname          string   `json:"hostname"`
	User              string   `json:"user"`
	SSHAuthorizedKeys []string `json:"ssh_authorized_keys"`
	Platform          string   `json:"platform"`
	Flavor            string   `json:"flavor"`
	Timezone          string   `json:"timezone"`
	ExtraPackages     []string `json:"extra_packages,omitempty"`
}

// DefaultConfig returns opinionated production defaults.
func DefaultConfig(flavor string) Config {
	return Config{
		Hostname: "lusoris-node",
		User:     "ubuntu",
		Platform: "proxmox",
		Flavor:   flavor,
		Timezone: "UTC",
	}
}

// GenerateUserData renders hardened cloud-init YAML user-data.
func GenerateUserData(cfg Config) (string, error) {
	if cfg.User == "" {
		cfg.User = "ubuntu"
	}
	if cfg.Hostname == "" {
		cfg.Hostname = "lusoris-node"
	}
	if cfg.Timezone == "" {
		cfg.Timezone = "UTC"
	}

	var sb strings.Builder
	sb.WriteString("#cloud-config\n")
	sb.WriteString("# Lusoris Hardened Cloud-Init User-Data\n\n")

	fmt.Fprintf(&sb, "hostname: %s\n", cfg.Hostname)
	fmt.Fprintf(&sb, "fqdn: %s.local\n", cfg.Hostname)
	sb.WriteString("manage_etc_hosts: true\n\n")

	sb.WriteString("users:\n")
	fmt.Fprintf(&sb, "  - name: %s\n", cfg.User)
	sb.WriteString("    gecos: Lusoris Operator\n")
	sb.WriteString("    sudo: ALL=(ALL) NOPASSWD:ALL\n")
	sb.WriteString("    groups: [adm, audio, cdrom, dialout, floppy, video, plugdev, dip, netdev, render, sudo]\n")
	sb.WriteString("    shell: /bin/bash\n")
	sb.WriteString("    lock_passwd: true\n")

	if len(cfg.SSHAuthorizedKeys) > 0 {
		sb.WriteString("    ssh_authorized_keys:\n")
		for _, key := range cfg.SSHAuthorizedKeys {
			if strings.TrimSpace(key) != "" {
				fmt.Fprintf(&sb, "      - %s\n", strings.TrimSpace(key))
			}
		}
	}
	sb.WriteString("\n")

	sb.WriteString("ssh_pwauth: false\n")
	sb.WriteString("disable_root: true\n\n")

	fmt.Fprintf(&sb, "timezone: %s\n\n", cfg.Timezone)

	sb.WriteString("growpart:\n")
	sb.WriteString("  mode: auto\n")
	sb.WriteString("  devices: ['/']\n")
	sb.WriteString("  ignore_growroot_disabled: false\n\n")

	appendPlatformUserData(&sb, cfg.Platform)

	if len(cfg.ExtraPackages) > 0 {
		sb.WriteString("packages:\n")
		for _, pkg := range cfg.ExtraPackages {
			fmt.Fprintf(&sb, "  - %s\n", pkg)
		}
		sb.WriteString("\n")
	}

	sb.WriteString("final_message: \"The Lusoris system is up, after $UPTIME seconds.\"\n")
	return sb.String(), nil
}

func appendPlatformUserData(sb *strings.Builder, platform string) {
	switch strings.ToLower(platform) {
	case "unraid":
		sb.WriteString("mounts:\n")
		sb.WriteString("  - [ share, /mnt/share, virtiofs, \"rw,sync\", \"0\", \"0\" ]\n\n")
	case "truenas":
		sb.WriteString("mounts:\n")
		sb.WriteString("  - [ nfs_share, /mnt/truenas, nfs, \"rw,hard,intr,noatime\", \"0\", \"0\" ]\n\n")
		sb.WriteString("write_files:\n")
		sb.WriteString("  - path: /etc/udev/rules.d/99-truenas-virtio.rules\n")
		sb.WriteString("    content: |\n")
		sb.WriteString("      ACTION==\"add|change\", SUBSYSTEM==\"block\", KERNEL==\"sd[a-z]|vd[a-z]\", ATTR{queue/discard_max_bytes}!=\"0\", ATTR{queue/discard_granularity}!=\"0\"\n\n")
	case "macos", "utm":
		sb.WriteString("mounts:\n")
		sb.WriteString("  - [ workspace, /mnt/workspace, virtiofs, \"rw,sync\", \"0\", \"0\" ]\n\n")
	case "windows", "hyperv":
		sb.WriteString("write_files:\n")
		sb.WriteString("  - path: /etc/modules-load.d/hyperv.conf\n")
		sb.WriteString("    content: |\n")
		sb.WriteString("      hv_vmbus\n      hv_storvsc\n      hv_netvsc\n      hv_utils\n\n")
	}
}

// GenerateMetaData renders cloud-init meta-data.
func GenerateMetaData(cfg Config) (string, error) {
	if cfg.Hostname == "" {
		cfg.Hostname = "lusoris-node"
	}
	var sb strings.Builder
	fmt.Fprintf(&sb, "instance-id: %s-01\n", cfg.Hostname)
	fmt.Fprintf(&sb, "local-hostname: %s\n", cfg.Hostname)
	return sb.String(), nil
}
