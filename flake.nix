{
  description = "🍁 Generate infrastructure and network diagrams directly from your NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    flake-utils.url = "github:numtide/flake-utils";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    flake-utils,
    nixpkgs,
    treefmt-nix,
    ...
  } @ inputs:
    {
      flakeModule = ./flake-module.nix;

      # Expose NixOS module
      nixosModules = rec {
        default = topology;
        topology = ./nixos/module.nix;
      };

      # A nixpkgs overlay that adds the parametrized builder as a package
      overlays = rec {
        default = topology;
        topology = import ./pkgs/default.nix;
      };
    }
    // flake-utils.lib.eachDefaultSystem (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [self.overlays.default];
        };
        treefmt = (treefmt-nix.lib.evalModule pkgs ./treefmt.nix).config.build;
      in {
        packages.docs = pkgs.callPackage ./pkgs/docs.nix {
          flakeInputs = inputs;
          flakeOutputs = self;
        };

        # `nix fmt`
        formatter = treefmt.wrapper;

        # `nix flake check`
        checks.formatting = treefmt.check self;

        # `nix develop`
        devShells.default = pkgs.mkShell {
          packages = [pkgs.mdbook];
        };
      }
    );
}
