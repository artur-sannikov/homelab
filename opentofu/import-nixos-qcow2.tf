resource "proxmox_virtual_environment_file" "nixos_bootstrap_qcow2" {
  node_name    = "pve2"
  datastore_id = "local"
  content_type = "import"

  source_file {
    path      = local.qcow2_path
    file_name = "nixos-bootstrap-uefi.qcow2"
  }

  overwrite = true

  depends_on = [
    terraform_data.build_nixos_qcow2,
  ]

  lifecycle {
    replace_triggered_by = [
      terraform_data.build_nixos_qcow2,
    ]
  }
}
