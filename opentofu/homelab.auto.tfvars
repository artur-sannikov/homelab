site = {
  placements = {
    pve1 = {
      node_name            = "pve1"
      datastore_id         = "local-zfs"
      bridge               = "vmbr0"
      snippet_datastore_id = "local"
    }

    pve2 = {
      node_name            = "pve2"
      datastore_id         = "local-zfs"
      bridge               = "vmbr0"
      snippet_datastore_id = "local"
    }
  }

  artifact_store = {
    placement    = "pve1"
    datastore_id = "truenas-iso"
  }

  networks = {
    services       = { vlan_id = 20 }
    infrastructure = { vlan_id = 40 }
    runners        = { vlan_id = 50 }
  }

  pool_id = "production"

  vm_ids = {
    "template/fedora-44-pve1"    = 9000
    "template/fedora-44-pve2"    = 9001
    "template/ubuntu-26-04-pve1" = 9002
    "template/ubuntu-26-04-pve2" = 9003
    "template/ubuntu-24-04-pve1" = 9004
    "template/ubuntu-24-04-pve2" = 9005
    "template/debian-13-pve1"    = 9006
    "template/debian-13-pve2"    = 9007

    "data/services"   = 118
    "data/monitoring" = 119

    "compute/codeberg_runner"         = 113
    "compute/tailscale_subnet_router" = 109
    "compute/services"                = 8000
    "compute/monitoring"              = 8001
  }
}
