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
            infisicalsdk
            python313Packages.virtualenv
          ];
          shellHook = ''
            if [ ! -d .venv ]; then
              python3 -m venv .venv
              source .venv/bin/activate
              pip install --upgrade pip
            else
              source .venv/bin/activate
            fi;
            ansible-galaxy collection install artis3n.tailscale
          '';
        };
      }
    );
}
