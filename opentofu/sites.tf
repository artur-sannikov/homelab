variable "site" {
  description = "Site-specific Proxmox topology"

  type = object({
    placements = map(object({
      node_name            = string
      datastore_id         = string
      bridge               = string
      snippet_datastore_id = optional(string, "local")
    }))

    networks = map(object({
      vlan_id = number
    }))

    pool_id = string

    artifact_store = object({
      placement    = string
      datastore_id = string
    })

    vm_ids = optional(map(number), {})

  })
}
