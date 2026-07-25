locals {
  description = "Managed by OpenTofu"

  # Default variables for compute VMs
  compute_defaults = {
    machine       = "q35"
    bios          = "ovmf"
    scsi_hardware = "virtio-scsi-single"

    boot_disk = {
      datastore_id = "local-zfs"
      interface    = "scsi0"
      iothread     = true
      ssd          = true
    }

    network = {
      bridge = "vmbr0"
      dhcp   = true
    }
  }

  # Stateful data disks
  data_vms = {
    services = {
      name      = "services-data-vm"
      node_name = "pve2"
      vm_id     = 118
      pool_id   = "production"
      tags      = ["datastore", "production"]
      size      = 8
    }
    monitoring = {
      name      = "monitoring-data-vm"
      node_name = "pve2"
      vm_id     = 119
      pool_id   = "production"
      tags      = ["datastore", "production"]
      size      = 8
    }
  }

  compute = {
    codeberg_runner = merge(local.compute_defaults, {
      name         = "codeberg-runner",
      node_name    = "pve2"
      vm_id        = 113
      template_key = "debian-13-pve2"

      os_tag      = "debian-13"
      boot_disk   = merge(local.compute_defaults.boot_disk, { size = 40 })
      memory_mb   = 4096
      cpu_cores   = 2
      vlan_id     = 50
      mac_address = var.codeberg_runner_mac_address
      reboot      = true
      data_vm_key = null # Does not have a data disk
    })

    tailscale_subnet_router = merge(local.compute_defaults, {
      name         = "tailscale-subnet-router",
      node_name    = "pve1"
      vm_id        = 109
      template_key = "debian-13-pve1"

      os_tag      = "debian-13"
      boot_disk   = merge(local.compute_defaults.boot_disk, { size = 8 })
      memory_mb   = 1024
      cpu_cores   = 1
      vlan_id     = 40
      mac_address = var.tailscale_subnet_router_mac_address
      reboot      = true
      data_vm_key = null # Does not have a data disk
    })

    services = merge(local.compute_defaults, {
      name         = "services"
      node_name    = "pve2"
      vm_id        = 8000
      template_key = "fedora-44-pve2"

      os_tag      = "fedora"
      boot_disk   = merge(local.compute_defaults.boot_disk, { size = 16 })
      memory_mb   = 8192
      cpu_cores   = 4
      vlan_id     = 20
      mac_address = var.services_mac_address
      reboot      = null
      data_vm_key = "services"
    })

    monitoring = merge(local.compute_defaults, {
      name         = "monitoring"
      node_name    = "pve2"
      vm_id        = 8001
      template_key = "fedora-44-pve2"

      os_tag      = "fedora"
      boot_disk   = merge(local.compute_defaults.boot_disk, { size = 16 })
      memory_mb   = 2048
      cpu_cores   = 2
      vlan_id     = 20
      mac_address = var.monitoring_mac_address
      reboot      = null
      data_vm_key = "monitoring"
    })
  }
}

### Stateful data VMs ###
resource "proxmox_virtual_environment_vm" "data" {
  for_each = local.data_vms

  description = local.description

  name      = each.value.name
  node_name = each.value.node_name
  vm_id     = each.value.vm_id
  pool_id   = each.value.pool_id

  started = false
  on_boot = false

  tags          = each.value.tags
  scsi_hardware = "virtio-scsi-single"

  protection = true

  disk {
    datastore_id = "local-zfs"
    interface    = "scsi2"
    file_format  = "raw"
    ssd          = true
    iothread     = true
    discard      = "on"
    size         = each.value.size
  }

  ### DO NOT DISABLE ###
  lifecycle {
    prevent_destroy = true
  }
  ######################
}

### Compute VMs ###
resource "proxmox_virtual_environment_vm" "compute" {
  for_each = local.compute

  description = local.description

  name      = each.value.name
  node_name = each.value.node_name
  vm_id     = each.value.vm_id

  template = false
  started  = true
  on_boot  = true

  machine       = each.value.machine
  bios          = each.value.bios
  scsi_hardware = each.value.scsi_hardware

  tags = [
    "cattle",
    "cloudinit",
    each.value.os_tag,
    "opentofu"
  ]

  reboot = each.value.reboot

  efi_disk {
    datastore_id = "local-zfs"
  }

  clone {
    vm_id = proxmox_virtual_environment_vm.templates[each.value.template_key].vm_id
  }

  disk {
    interface    = each.value.boot_disk.interface
    datastore_id = each.value.boot_disk.datastore_id
    iothread     = each.value.boot_disk.iothread
    ssd          = each.value.boot_disk.ssd
    size         = each.value.boot_disk.size
  }

  # Add data disk only for compute nodes that require it
  dynamic "disk" {
    for_each = each.value.data_vm_key == null ? {} : {
      data = proxmox_virtual_environment_vm.data[each.value.data_vm_key].disk[0]
    }
    iterator = attached_disk

    content {
      interface    = attached_disk.value.interface
      datastore_id = attached_disk.value.datastore_id
      file_format  = attached_disk.value.file_format
      size         = attached_disk.value.size
    }
  }

  memory {
    dedicated = each.value.memory_mb
    floating  = each.value.memory_mb
  }

  cpu {
    cores = each.value.cpu_cores
    type  = "host"
  }

  network_device {
    bridge      = each.value.network.bridge
    vlan_id     = each.value.vlan_id
    mac_address = each.value.mac_address
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
