variable "codeberg_runner_mac_address" {
  description = "MAC address of the Codeberg runner"
  type        = string
}

variable "tailscale_subnet_router_mac_address" {
  description = "MAC address of the Tailscale subnet router"
  type        = string
}

variable "ssh_public_keys" {
  description = "SSH keys to add into the VM via cloud-init"
  type        = list(string)
}

variable "infisical_client_id" {
  type      = string
  sensitive = true
}

variable "infisical_client_secret" {
  type      = string
  sensitive = true
}

variable "infisical_url" {
  type = string
}

variable "infisical_workspace_id" {
  type = string
}
