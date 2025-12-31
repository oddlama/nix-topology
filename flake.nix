{
  description = "🍁 Generate infrastructure and network diagrams directly from your NixOS configurations";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    {
      self,
      flake-parts,
      nixpkgs,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

      imports = with flake-parts.flakeModules; [
        partitions
        flakeModules
      ];

      partitions.dev = {
        extraInputsFlake = ./dev;
        module = ./dev;
      };
      partitionedAttrs = {
        checks = "dev";
        devShells = "dev";
        formatter = "dev";
      };

      flake = {
        flakeModule = ./flake-module.nix;

        # Expose NixOS module
        nixosModules = {
          topology = ./nixos/module.nix;
          default = self.nixosModules.topology;
        };

        # A nixpkgs overlay that adds the parametrized builder as a package
        overlays = {
          default = self.overlays.topology;
          topology = import ./pkgs/default.nix;
        };
      };

      perSystem =
        { pkgs, ... }:
        {
          packages.docs = pkgs.callPackage ./pkgs/docs.nix {
            flakeInputs = inputs;
            flakeOutputs = self;
          };
        };
    };
}
