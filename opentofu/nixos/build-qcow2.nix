{
  config,
  lib,
  pkgs,
  ...
}:

{
  imports = [
    ./machine-config.nix
  ];

  system.build.qcow2 = import <nixpkgs/nixos/lib/make-disk-image.nix> {
    inherit lib config pkgs;

    format = "qcow2";
    diskSize = 8192;
    partitionTableType = "efi";

    configFile = pkgs.writeText "configuration.nix" ''
      { ... }:
      {
        imports = [
          ${./machine-config.nix}
        ];
      }
    '';
  };
}
