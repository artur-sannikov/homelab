resource "proxmox_network_linux_vlan" "vlan10" {
  address        = "192.168.10.5/24"
  autostart      = true
  comment        = "Managed by OpenTofu: Management"
  gateway        = "192.168.10.1"
  interface      = "vmbr0"
  name           = "vmbr0.10"
  node_name      = "pve1"
  reload         = true
  timeout_reload = 100
  vlan           = 10
}


resource "proxmox_network_linux_vlan" "vlan20" {
  address        = "192.168.20.6/24"
  autostart      = true
  comment        = "Managed by OpenTofu: Servers"
  interface      = "vmbr0"
  name           = "vmbr0.20"
  node_name      = "pve1"
  reload         = true
  timeout_reload = 100
  vlan           = 20
}

resource "proxmox_network_linux_vlan" "vlan40" {
  address        = "192.168.40.5/24"
  autostart      = true
  comment        = "Managed by OpenTofu: Caddy"
  interface      = "vmbr0"
  name           = "vmbr0.40"
  node_name      = "pve1"
  reload         = true
  timeout_reload = 100
  vlan           = 40
}

resource "proxmox_network_linux_vlan" "vlan50" {
  address        = "192.168.50.7/24"
  autostart      = true
  comment        = "Managed by OpenTofu: Clean Internet"
  interface      = "vmbr0"
  name           = "vmbr0.50"
  node_name      = "pve1"
  reload         = true
  timeout_reload = 100
  vlan           = 50
}
