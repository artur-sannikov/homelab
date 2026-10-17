locals {
  vlan_config = {
    pve1 = {
      management = {
        vlan    = 10
        address = "192.168.10.5/24"
        gateway = "192.168.10.1"
        comment = "Managed by OpenTofu: Management"
      }

      servers = {
        vlan    = 20
        address = "192.168.20.6/24"
        comment = "Managed by OpenTofu: Servers"
      }

      dmz = {
        vlan    = 40
        address = "192.168.40.5/24"
        comment = "Managed by OpenTofu: DMZ"
      }

      clean_internet = {
        vlan    = 50
        address = "192.168.50.7/24"
        comment = "Managed by OpenTofu: Clean Internet"
      }
    }

    pve2 = {
      management = {
        vlan    = 10
        address = "192.168.10.6/24"
        gateway = "192.168.10.1"
        comment = "Managed by OpenTofu: Management"
      }

      servers = {
        vlan    = 20
        address = "192.168.20.7/24"
        comment = "Managed by OpenTofu: Servers"
      }

      dmz = {
        vlan    = 40
        address = "192.168.40.6/24"
        comment = "Managed by OpenTofu: DMZ"
      }

      clean_internet = {
        vlan    = 50
        address = "192.168.50.6/24"
        comment = "Managed by OpenTofu: Clean Internet"
      }
    }
  }

  vlans = merge([
    for node_name, node_vlans in local.vlan_config : {
      for vlan_name, vlan_config in node_vlans :
      "${node_name}-${vlan_name}" => merge(vlan_config, {
        node_name = node_name
        name      = "vmbr0.${vlan_config.vlan}"
        interface = "vmbr0"
      })
    }
  ]...)
}

resource "proxmox_network_linux_vlan" "vlan" {
  for_each = local.vlans

  node_name = each.value.node_name
  name      = each.value.name
  interface = each.value.interface

  vlan    = each.value.vlan
  address = each.value.address
  gateway = try(each.value.gateway, null)
  comment = each.value.comment

  autostart      = true
  reload         = true
  timeout_reload = 100
}
