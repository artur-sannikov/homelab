resource "proxmox_virtual_environment_vm" "nixos_anywhere_template" {
  name        = "nixos-anywhere-bootstrap"
  description = "Managed by OpenTofu"
  node_name   = "pve2"
  vm_id       = 9009

  template = true
  started  = false

  bios = "ovmf"

  tags = [
    "nixos",
    "opentofu",
  ]

  cpu {
    cores = 1
    type  = "host"
  }

  efi_disk {
    datastore_id      = "local-zfs"
    type              = "4m"
    pre_enrolled_keys = false
  }

  memory {
    dedicated = 1024
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_virtual_environment_file.nixos_bootstrap_qcow2.id
    interface    = "scsi0"
    ssd          = true
    size         = 8
  }

  network_device {
    bridge = "vmbr0"
  }

  operating_system {
    type = "l26"
  }

  depends_on = [
    proxmox_virtual_environment_file.nixos_bootstrap_qcow2,
  ]

  lifecycle {
    replace_triggered_by = [
      proxmox_virtual_environment_file.nixos_bootstrap_qcow2,
    ]
  }
}
