locals {
  image_dir   = "${path.module}/.generated"
  result_path = "${local.image_dir}/nixos-bootstrap.qcow2"
  qcow2_path  = "${local.result_path}/nixos.qcow2"
}

resource "terraform_data" "build_nixos_qcow2" {
  triggers_replace = {
    machine_config = filesha256("${path.module}/nixos/machine-config.nix")
    image_config   = filesha256("${path.module}/nixos/build-qcow2.nix")
  }

  provisioner "local-exec" {
    working_dir = path.module
    interpreter = ["/usr/bin/env", "bash", "-c"]

    command = <<-EOT
      set -e

      mkdir -p "${local.image_dir}"

      nix-build \
        '<nixpkgs/nixos>' \
        -A config.system.build.qcow2 \
        --arg configuration '{ imports = [ ./nixos/build-qcow2.nix ]; }' \
        -o "${local.result_path}"

      # Test that the file exists
      test -f "${local.qcow2_path}"

      echo "Built NixOS image:"
      readlink -f "${local.qcow2_path}"
    EOT

  }
}
