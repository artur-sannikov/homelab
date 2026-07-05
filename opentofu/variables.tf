variable "proxmox_endpoint" {
  description = "Proxmox URL"
  type        = string
  sensitive   = true
}

variable "proxmox_api_token" {
  description = "Proxmox API Token for opentofu user"
  type        = string
  sensitive   = true
}

variable "codeberg_runner_mac_address" {
  description = "MAC address of the Codeberg runner"
  type        = string
}

variable "ssh_public_keys" {
  description = "SSH keys to add into the VM via cloud-init"
  type        = list(string)
}
