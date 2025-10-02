{
  description = "My ansible + infisicalsdk dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      nixpkgs,
      flake-utils,
      ...
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfreePredicate =
            pkgs:
            builtins.elem (nixpkgs.lib.getName pkgs) [
              # Remove when updated with MIT license
              "infisicalsdk"
            ];
        };
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [
            python313
            python313Packages.ansible
            python313Packages.ansible-core
            infisicalsdk
            ansible-lint
            python313Packages.virtualenv
          ];
          shellHook = ''
            export ANSIBLE_COLLECTIONS_PATH="$PWD/ansible_collections"
            ansible-galaxy install -r requirements.yaml
          '';
        };
      }
    );
}
