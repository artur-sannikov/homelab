{
  description = "My ansible + infisicalsdk dev environment";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/x86_64-linux";
    git-hooks.url = "github:cachix/git-hooks.nix";
  };
  outputs =
    {
      self,
      systems,
      nixpkgs,
      ...
    }@inputs:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      # Run the hooks with `nix fmt`.
      formatter = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          config = self.checks.${system}.pre-commit-check.config;
          inherit (config) package configFile;
          script = ''
            ${pkgs.lib.getExe package} run --all-files --config ${configFile}
          '';
        in
        pkgs.writeShellScriptBin "pre-commit-run" script
      );

      # Run the hooks in a sandbox with `nix flake check`.
      # Read-only filesystem and no internet access.
      checks = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
        in
        {
          pre-commit-check = inputs.git-hooks.lib.${system}.run {
            src = ./.;
            hooks = {
              nixfmt.enable = true;

              gitleaks = {
                enable = true;
                name = "gitleaks";
                entry = "${pkgs.gitleaks}/bin/gitleaks protect --staged";
              };

              detect-private-key = {
                enable = true;
                name = "detect-private-key";
                entry = "${pkgs.python3Packages.pre-commit-hooks}/bin/detect-private-key";
              };
              check-merge-conflict = {
                enable = true;
                name = "check-merge-conflict";
                entry = "${pkgs.python3Packages.pre-commit-hooks}/bin/check-merge-conflict";
              };
              trailing-whitespace = {
                enable = true;
                name = "trailing-whitespace";
                entry = "${pkgs.python3Packages.pre-commit-hooks}/bin/trailing-whitespace-fixer";
              };
              end-of-file-fixer = {
                enable = true;
                name = "end-of-file-fixer";
                entry = "${pkgs.python3Packages.pre-commit-hooks}/bin/end-of-file-fixer";
              };
              check-added-large-files = {
                enable = true;
                name = "check-added-large-files";
                entry = "${pkgs.python3Packages.pre-commit-hooks}/bin/check-added-large-files";
              };
            };
          };
        }
      );
      devShells = forEachSystem (system: {
        default =
          let
            pkgs = nixpkgs.legacyPackages.${system};
            inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
          in
          pkgs.mkShell {
            shellHook = shellHook + ''
              export ANSIBLE_COLLECTIONS_PATH="$PWD/ansible_collections"
              ansible-galaxy install -r requirements.yaml
            '';

            buildInputs = enabledPackages ++ [
              pkgs.ansible-lint
              pkgs.infisicalsdk
              pkgs.python313
              pkgs.python313Packages.ansible
              pkgs.python313Packages.ansible-core
              pkgs.rbw
              pkgs.renovate
            ];
          };
      });
    };
}
