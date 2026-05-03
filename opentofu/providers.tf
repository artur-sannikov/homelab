terraform {
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.105.0"
    }
  }
}

provider "proxmox" {
  endpoint  = var.proxmox_endpoint
  api_token = var.proxmox_api_token
  insecure  = false
}
