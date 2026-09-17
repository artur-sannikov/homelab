locals {
  description = "Managed by OpenTofu"

  # Default variables for compute VMs
  compute_defaults = {
    machine       = "q35"
    bios          = "ovmf"
    scsi_hardware = "virtio-scsi-single"

    boot_disk = {
      interface = "scsi0"
      discard   = "on"
      iothread  = true
      ssd       = true
      aio       = "native"
    }

    network = {
      bridge = "vmbr0"
      dhcp   = true
    }
  }

  # Stateful data disks
  data_vm_definitions = {
    services = {
      name      = "services-data-vm"
      placement = "pve2"
      node_name = var.site.placements["pve2"].node_name
      pool_id   = "production"
      tags      = ["datastore", "production"]
      size      = 8
    }
    monitoring = {
      name      = "monitoring-data-vm"
      placement = "pve2"
      node_name = var.site.placements["pve2"].node_name
      pool_id   = "production"
      tags      = ["datastore", "production"]
      size      = 8
    }
  }

  data_vms = {
    for key, vm in local.data_vm_definitions : key => merge(vm, {
      node_name = var.site.placements[
        vm.placement
      ].node_name

      datastore_id = var.site.placements[
        vm.placement
      ].datastore_id

      pool_id = var.site.pool_id
    })
  }
  compute_definitions = {
    codeberg_runner = merge(local.compute_defaults, {
      name         = "codeberg-runner",
      placement    = "pve2"
      node_name    = var.site.placements["pve2"].node_name
      template_key = "debian-13-pve2"

      os_tag       = "debian-13"
      boot_disk    = merge(local.compute_defaults.boot_disk, { size = 40 })
      memory_mb    = 4096
      cpu_cores    = 2
      network_name = "runners"
      mac_address  = var.codeberg_runner_mac_address
      reboot       = true
      data_vm_key  = null # Does not have a data disk
    })

    tailscale_subnet_router = merge(local.compute_defaults, {
      name         = "tailscale-subnet-router",
      placement    = "pve1"
      node_name    = var.site.placements["pve1"].node_name
      template_key = "debian-13-pve1"

      os_tag       = "debian-13"
      boot_disk    = merge(local.compute_defaults.boot_disk, { size = 8 })
      memory_mb    = 1024
      cpu_cores    = 1
      network_name = "infrastructure"
      mac_address  = var.tailscale_subnet_router_mac_address
      reboot       = true
      data_vm_key  = null # Does not have a data disk
    })

    services = merge(local.compute_defaults, {
      name         = "services"
      placement    = "pve2"
      node_name    = var.site.placements["pve2"].node_name
      template_key = "fedora-44-pve2"

      os_tag       = "fedora"
      boot_disk    = merge(local.compute_defaults.boot_disk, { size = 32 })
      memory_mb    = 8192
      cpu_cores    = 4
      network_name = "services"
      mac_address  = var.services_mac_address
      reboot       = null
      data_vm_key  = "services"
    })

    monitoring = merge(local.compute_defaults, {
      name         = "monitoring"
      placement    = "pve2"
      node_name    = var.site.placements["pve2"].node_name
      template_key = "fedora-44-pve2"

      os_tag       = "fedora"
      boot_disk    = merge(local.compute_defaults.boot_disk, { size = 32 })
      memory_mb    = 2048
      cpu_cores    = 2
      network_name = "services"
      mac_address  = var.monitoring_mac_address
      reboot       = null
      data_vm_key  = "monitoring"
    })
  }

  compute = {
    for key, vm in local.compute_definitions : key => merge(vm, {
      node_name = var.site.placements[
        vm.placement
      ].node_name

      datastore_id = var.site.placements[
        vm.placement
      ].datastore_id

      bridge = var.site.placements[
        vm.placement
      ].bridge

      boot_disk = merge(vm.boot_disk, {
        datastore_id = var.site.placements[
          vm.placement
        ].datastore_id
      })
      vlan_id = var.site.networks[
        vm.network_name
      ].vlan_id
    })
  }
}

### Stateful data VMs ###
resource "proxmox_virtual_environment_vm" "data" {
  for_each = local.data_vms

  description = local.description

  name      = each.value.name
  node_name = each.value.node_name
  vm_id     = lookup(var.site.vm_ids, "data/${each.key}", null)
  pool_id   = each.value.pool_id

  started = false
  on_boot = false

  tags          = each.value.tags
  scsi_hardware = "virtio-scsi-single"

  protection = true

  disk {
    datastore_id = each.value.datastore_id
    interface    = "scsi2"
    file_format  = "raw"
    ssd          = true
    iothread     = true
    discard      = "on"
    aio          = "native"
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
  vm_id     = lookup(var.site.vm_ids, "compute/${each.key}", null)

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
    datastore_id = each.value.datastore_id
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
      aio          = "native"
      ssd          = true
      iothread     = true
      discard      = "on"
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
    bridge      = each.value.bridge
    vlan_id     = each.value.vlan_id
    mac_address = each.value.mac_address
  }

  initialization {
    datastore_id = each.value.datastore_id

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
