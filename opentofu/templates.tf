locals {
  # All templates with VM IDs per node
  os_templates = {
    "fedora-44" = {
      machine            = "q35"
      tags               = ["cattle", "cloudinit", "fedora-44", "opentofu", "template"]
      image_url          = "https://mirror.dogado.de/fedora/linux/releases/44/Cloud/x86_64/images/Fedora-Cloud-Base-AmazonEC2-44-1.7.x86_64.raw.xz"
      image_filename     = "Fedora-Cloud-Base-AmazonEC2-44-1.7.x86_64.raw.xz.img"
      checksum           = "7e4fb73907abdc761d226ddaf3263bdfca62a0b0bfb5f0798545a9981fdd1953"
      checksum_algorithm = "sha256"
      decompression      = "zst"
      overwrite          = false
      snippet_family     = "fedora"
      nodes = {
        pve1 = { vm_id = 9000 }
        pve2 = { vm_id = 9001 }
      }
    }
    "ubuntu-26-04" = {
      machine            = "pc"
      tags               = ["cattle", "cloudinit", "ubuntu-26-04", "opentofu", "template"]
      image_url          = "https://cloud-images.ubuntu.com/resolute/20260627/resolute-server-cloudimg-amd64.img"
      image_filename     = "resolute-server-cloudimg-amd64.img"
      checksum           = "3ee4f67f322abb2d1d1f0fffc957f7411404ad6635dd35b026c8ff05ac6e534c"
      checksum_algorithm = "sha256"
      decompression      = null
      overwrite          = true
      snippet_family     = "debian"
      nodes = {
        pve1 = { vm_id = 9002 }
        pve2 = { vm_id = 9003 }
      }
    }
    "ubuntu-24-04" = {
      machine            = "q35"
      tags               = ["cattle", "cloudinit", "ubuntu-24-04", "opentofu", "template"]
      image_url          = "https://cloud-images.ubuntu.com/noble/20260615/noble-server-cloudimg-amd64.img"
      image_filename     = "noble-server-cloudimg-amd64.img"
      checksum           = "5fa5b05e5ec239858c4531485d6023b0896448c2df7c63b34f8dae6ea6051a44"
      checksum_algorithm = "sha256"
      decompression      = null
      overwrite          = true
      snippet_family     = "debian"
      nodes = {
        pve1 = { vm_id = 9004 }
        pve2 = { vm_id = 9005 }
      }
    }

    "debian-13" = {
      machine            = "q35"
      tags               = ["cattle", "cloudinit", "debian", "opentofu", "template"]
      image_url          = "https://cloud.debian.org/images/cloud/trixie/20260623-2518/debian-13-generic-amd64-20260623-2518.raw"
      image_filename     = "debian-13-generic-amd64-20260623-2518.raw.img" # Rename for Proxmox
      checksum           = "1be966edeae243905fadeaa8e9942168b75820fa2350357066a9dd3fa4b4d6ec5c8d6b783fdce3bb5c9665eaa0250f1be328e646c6847d7e6b3c4ade2b3eb4f8"
      checksum_algorithm = "sha512"
      decompression      = null
      overwrite          = true
      snippet_family     = "debian"
      nodes = {
        pve1 = { vm_id = 9006 }
        pve2 = { vm_id = 9007 }
      }
    }
  }

  # Snippets for each OS family
  snippet_definitions = {
    fedora = {
      file_name = "fedora.yaml"
      data      = <<-EOF
        #cloud-config
        package_update: true
        packages:
            - qemu-guest-agent
        runcmd:
            - systemctl enable --now qemu-guest-agent
            - systemctl enable sshd
            - reboot
      EOF
    }
    debian = {
      file_name = "debian.yaml"
      data      = <<-EOF
        #cloud-config
        package_update: true
        packages:
            - qemu-guest-agent
        runcmd:
            - systemctl enable --now qemu-guest-agent
            - systemctl enable ssh
            - reboot
      EOF
    }
  }

  # Flatten the configuration into a list of individual instances per node
  template_instances = flatten([
    for os, config in local.os_templates : [
      for node_name, node_data in config.nodes : {
        instance_key       = "${os}-${node_name}"
        os                 = os
        node_name          = node_name
        vm_id              = node_data.vm_id
        name               = "${os}-template"
        machine            = config.machine
        tags               = config.tags
        snippet_family     = config.snippet_family
        image_filename     = config.image_filename
        image_url          = config.image_url
        checksum           = config.checksum
        checksum_algorithm = config.checksum_algorithm
        decompression      = config.decompression
        overwrite          = config.overwrite
      }
    ]
  ])

  # Create a map for the for_each iteration
  template_instances_map = {
    for inst in local.template_instances : inst.instance_key => inst
  }
  snippet_instances = {
    for k, v in {
      for inst in local.template_instances :
      "${inst.snippet_family}-${inst.node_name}" => {
        snippet_family = inst.snippet_family
        node_name      = inst.node_name
      }...
      # Produces duplicates ubuntu-pve1 and ubuntu-pve2
      # The solution below extracts only the first duplicated key
    } : k => v[0]
  }
}

resource "proxmox_download_file" "template_images" {
  for_each = local.os_templates

  content_type = "iso"
  datastore_id = "truenas-iso"
  node_name    = "pve1"

  file_name               = each.value.image_filename
  decompression_algorithm = each.value.decompression
  url                     = each.value.image_url
  checksum                = each.value.checksum
  checksum_algorithm      = each.value.checksum_algorithm
  overwrite               = each.value.overwrite
}

resource "proxmox_virtual_environment_file" "snippets" {
  for_each     = local.snippet_instances
  content_type = "snippets"
  datastore_id = "local"
  node_name    = each.value.node_name

  source_raw {
    file_name = local.snippet_definitions[each.value.snippet_family].file_name
    data      = local.snippet_definitions[each.value.snippet_family].data
  }
}

resource "proxmox_virtual_environment_vm" "templates" {
  for_each  = local.template_instances_map
  name      = each.value.name
  node_name = each.value.node_name
  vm_id     = each.value.vm_id

  template = true
  started  = false

  machine = each.value.machine
  bios    = "ovmf"

  tags = each.value.tags

  cpu {
    cores = 1
    type  = "host"
  }

  efi_disk {
    datastore_id = "local-zfs"
  }

  memory {
    dedicated = 1024
  }

  disk {
    datastore_id = "local-zfs"
    file_id      = proxmox_download_file.template_images[each.value.os].id
    interface    = "scsi0"
    ssd          = true
    discard      = "on"
    backup       = false
  }

  boot_order = ["scsi0"]

  network_device {
    bridge = "vmbr0"
  }

  agent {
    enabled = true
  }

  initialization {
    datastore_id = "local-zfs"
    interface    = "scsi1"

    ip_config {
      ipv4 {
        address = "dhcp"
      }
    }
    vendor_data_file_id = proxmox_virtual_environment_file.snippets["${each.value.snippet_family}-${each.value.node_name}"].id

    user_account {
      username = "artur"
      keys     = var.ssh_public_keys
    }
  }

  operating_system {
    type = "l26"
  }
}
