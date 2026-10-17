locals {
  proxmox_nodes = {
    pve1 = {}
    pve2 = {}
  }
}

resource "proxmox_apt_standard_repository" "no_subscription" {
  for_each = local.proxmox_nodes

  node   = each.key
  handle = "no-subscription"
}

resource "proxmox_apt_repository" "no_subscription" {
  for_each = proxmox_apt_standard_repository.no_subscription

  node      = each.value.node
  file_path = each.value.file_path
  index     = each.value.index

  enabled = true
}

resource "proxmox_apt_standard_repository" "enterprise" {
  for_each = local.proxmox_nodes

  node   = each.key
  handle = "enterprise"
}

resource "proxmox_apt_repository" "enterprise" {
  for_each = proxmox_apt_standard_repository.enterprise

  node      = each.value.node
  file_path = each.value.file_path
  index     = each.value.index

  enabled = false
}
