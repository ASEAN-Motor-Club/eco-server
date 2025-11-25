# SPDX-License-Identifier: Unlicense
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs =
    { self, nixpkgs, systems, ... }@inputs:
    let
      eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
    in
    {
      nixosModules.default = import ./server.nix;

      devShells = eachSystem (pkgs: {
        default = pkgs.mkShell {
          buildInputs = with pkgs; [
            (pkgs.writeShellScriptBin "deploy-scripts" (builtins.readFile ./deploy_mod.sh))
            # Add development dependencies here
          ];
        };
      });
    };
}
