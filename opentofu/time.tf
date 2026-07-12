resource "proxmox_virtual_environment_time" "node_time" {
  for_each  = toset(data.proxmox_virtual_environment_nodes.available_nodes.names)
  node_name = each.value
  time_zone = "Europe/Helsinki"
}
