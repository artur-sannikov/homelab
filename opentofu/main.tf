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

resource "proxmox_virtual_environment_vm" "tailscale-subnet-router" {
  name      = "tailscale-subnet-router"
  node_name = "pve1"
  vm_id     = 109

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
    vm_id = proxmox_virtual_environment_vm.templates["debian-13-pve1"].vm_id
  }

  # Boot disk
  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    size         = 8
  }

  memory {
    dedicated = 1024
    floating  = 1024
  }

  cpu {
    cores = 1
    type  = "host"
  }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = 40
    mac_address = var.tailscale_subnet_router_mac_address
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

resource "proxmox_virtual_environment_vm" "services_data_vm" {
  name      = "services-data-vm"
  node_name = "pve2"
  vm_id     = 118
  pool_id   = "production"

  started = false
  on_boot = false

  description   = "Managed by OpenTofu"
  tags          = ["datastore", "production"]
  scsi_hardware = "virtio-scsi-single"

  protection = true

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi2"
    file_format  = "raw"
    ssd          = true
    iothread     = true
    discard      = "on" # Enable thin provisioning to save space
    size         = 8
  }

  # This is the stateful data disk
  lifecycle {
    prevent_destroy = true
  }
}

resource "proxmox_virtual_environment_vm" "services" {
  name      = "services"
  node_name = "pve2"
  vm_id     = 8000

  template = false
  started  = true
  on_boot  = true

  machine       = "q35"
  bios          = "ovmf"
  description   = "Managed by OpenTofu"
  tags          = ["cattle", "cloudinit", "fedora", "opentofu"]
  scsi_hardware = "virtio-scsi-single"

  # Required for bios = "ovmf"
  efi_disk {
    datastore_id = "local-zfs"
  }

  clone {
    vm_id = proxmox_virtual_environment_vm.templates["fedora-44-pve2"].vm_id
  }


  # Boot disk
  disk {
    datastore_id = "local-zfs"
    interface    = "scsi0"
    iothread     = true
    ssd          = true
    size         = 16
  }

  disk {
    datastore_id      = proxmox_virtual_environment_vm.services_data_vm.disk[0].datastore_id
    path_in_datastore = proxmox_virtual_environment_vm.services_data_vm.disk[0].path_in_datastore
    file_format       = proxmox_virtual_environment_vm.services_data_vm.disk[0].file_format
    size              = proxmox_virtual_environment_vm.services_data_vm.disk[0].size
    interface         = proxmox_virtual_environment_vm.services_data_vm.disk[0].interface
  }

  memory {
    dedicated = 8192
    floating  = 8192
  }

  cpu {
    cores = 4
    type  = "host"
  }

  network_device {
    bridge      = "vmbr0"
    vlan_id     = 20
    mac_address = var.services_mac_address
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
