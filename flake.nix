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
         "StorageControl" = pkgs.fetchzip {
           url = "https://g-6.modapi.io/v1/games/6/mods/5203090/files/6835797/download";
           hash = "sha256-QHm1HVzRJ+pK2VQ8P3CbAwkoy4oS3myYGXAAJVGwWlA=";
         };
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
