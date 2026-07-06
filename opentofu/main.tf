resource "proxmox_virtual_environment_vm" "codeberg-runner" {
  name      = "codeberg-runner"
  node_name = "pve2"
  vm_id     = 113

  template = false
  started  = true
  on_boot  = true

  machine       = "q35"
  bios          = "ovmf"
  description   = "Managed by OpenTofu"
  tags          = ["cattle", "cloudinit", "debian-13", "opentofu"]
  scsi_hardware = "virtio-scsi-single"

  reboot = true

  # Required for bios = "ovmf"
  efi_disk {
    datastore_id = "local-zfs"
  }

  clone {
    vm_id = proxmox_virtual_environment_vm.templates["debian-13-pve2"].vm_id
  }

  # Boot disk
  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    size         = 40
  }

  memory {
    dedicated = 4096
    floating  = 4096
  }

  cpu {
    cores = 2
    type  = "host"
  }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = 50
    mac_address = var.codeberg_runner_mac_address
  }

  initialization {
    datastore_id = "local-zfs"
    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
  }

  agent {
    enabled = true
  }
}
