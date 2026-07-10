ephemeral "infisical_secret" "proxmox_config" {
  name         = "PROXMOX_CREDENTIALS"
  env_slug     = "prod"
  workspace_id = var.infisical_workspace_id
  folder_path  = "/"
}

terraform {
  required_version = "~> 1.15.0"
  required_providers {
    proxmox = {
      source  = "bpg/proxmox"
      version = "0.111.1"
    }
    infisical = {
      source  = "infisical/infisical"
      version = "0.19.1"
    }
  }
}

provider "proxmox" {
  endpoint  = jsondecode(ephemeral.infisical_secret.proxmox_config.value)["url"]
  api_token = jsondecode(ephemeral.infisical_secret.proxmox_config.value)["api_token"]
  insecure  = false

  ssh {
    agent    = true
    username = "root"
  }
}

provider "infisical" {
  host = var.infisical_url
  auth = {
    universal = {
      client_id     = var.infisical_client_id
      client_secret = var.infisical_client_secret
    }
  }
}
