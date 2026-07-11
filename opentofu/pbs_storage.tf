data "infisical_secrets" "pbs_credentials" {
  env_slug     = "prod"
  workspace_id = var.infisical_workspace_id
  folder_path  = "/pbs"
}

resource "proxmox_storage_pbs" "pbs-limited" {
  id        = "pbs-limited"
  nodes     = ["pve1", "pve2"]
  server    = data.infisical_secrets.pbs_credentials.secrets["PBS_URL"].value
  datastore = "pve-datastore"

  username = "backupUser@pbs!pve"

  ### Use ephemeral resources once this is merged: ###
  ### https://github.com/bpg/terraform-provider-proxmox/pull/2960 ###

  password       = data.infisical_secrets.pbs_credentials.secrets["PBS_API_TOKEN"].value
  encryption_key = data.infisical_secrets.pbs_credentials.secrets["PBS_ENCRYPTION_KEY"].value

  content = ["backup"]
}
