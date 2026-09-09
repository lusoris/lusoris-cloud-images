variable "image_name" {
  type        = string
  default     = "lusoris-cloud"
  description = "Base output name for the generated image"
}

variable "flavor" {
  type        = string
  default     = "base-generic"
  description = "Target image flavor across the 4D matrix"
}

variable "distro_version" {
  type        = string
  default     = "26.04"
  description = "Base distribution version (Ubuntu 26.04 LTS Resolute)"
}

variable "iso_url" {
  type        = string
  default     = "https://cloud-images.ubuntu.com/daily/server/resolute/current/resolute-server-cloudimg-amd64.img"
  description = "URL to upstream cloud image (QCOW2 or raw disk)"
}

variable "iso_checksum" {
  type        = string
  default     = "file:https://cloud-images.ubuntu.com/daily/server/resolute/current/SHA256SUMS"
  description = "Checksum verification file URL"
}

variable "disk_size" {
  type        = string
  default     = "20G"
  description = "Target virtual disk size"
}

variable "memory" {
  type        = number
  default     = 4096
  description = "RAM allocated during the build in MB"
}

variable "cpus" {
  type        = number
  default     = 4
  description = "vCPU count allocated during the build"
}

variable "output_dir" {
  type        = string
  default     = "output-images"
  description = "Directory where the final images are placed"
}

variable "ssh_username" {
  type        = string
  default     = "ubuntu"
  description = "SSH username used by cloud-init for build access"
}

variable "ssh_password" {
  type        = string
  default     = "ubuntu"
  sensitive   = true
  description = "Temporary SSH password for cloud-init build"
}

# Proxmox-specific variables (used when deploying to Proxmox VE)
variable "proxmox_url" {
  type        = string
  default     = "https://127.0.0.1:8006/api2/json"
  description = "Proxmox API URL (e.g. https://pve.example.com:8006/api2/json)"
}

variable "proxmox_token_id" {
  type        = string
  default     = "terraform@pve!terraform"
  description = "Proxmox API token ID"
}

variable "proxmox_token_secret" {
  type        = string
  default     = "placeholder-secret"
  sensitive   = true
  description = "Proxmox API token secret"
}

variable "proxmox_node" {
  type        = string
  default     = "pve"
  description = "Target Proxmox node"
}

variable "proxmox_skip_tls_verify" {
  type        = bool
  default     = true
  description = "Skip Proxmox TLS verification"
}

variable "storage_pool" {
  type        = string
  default     = "local-lvm"
  description = "Proxmox storage pool for templates"
}

variable "vm_id" {
  type        = number
  default     = 9000
  description = "Base VM ID for Proxmox template"
}
