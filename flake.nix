# SPDX-License-Identifier: Unlicense
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    systems.url = "github:nix-systems/default";
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    ...
  } @ inputs: let
    eachSystem = f: nixpkgs.lib.genAttrs (import systems) (system: f nixpkgs.legacyPackages.${system});
  in {
    nixosModules.default = import ./server.nix;

    # AMC-specific server configuration
    # Usage: imports = [ eco-server.nixosModules.amc ];
    nixosModules.amc = {config, lib, pkgs, ...}: {
      imports = [./server.nix];
      config.services.eco-server.mods = lib.mkDefault {
        # "ModFolderName" = pkgs.fetchzip {
        #   url = "https://mod.io/download/...";
        #   hash = "";
        # };
      };
    };

    devShells = eachSystem (pkgs: {
      default = pkgs.mkShell {
        buildInputs = with pkgs; [
          # Add development dependencies here
        ];
      };
    });
  };
}
