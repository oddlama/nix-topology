{
  description = "🍁 Generate infrastructure and network diagrams directly from your NixOS configurations";

  inputs = {
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      devshell,
      flake-parts,
      nixpkgs,
      pre-commit-hooks,
      ...
    }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = nixpkgs.lib.systems.flakeExposed;

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
        { system, pkgs, ... }:
        {
          _module.args.pkgs = import nixpkgs {
            inherit system;
            overlays = [
              self.overlays.default
              devshell.overlays.default
            ];
          };

          packages.docs = pkgs.callPackage ./pkgs/docs.nix {
            flakeInputs = inputs;
            flakeOutputs = self;
          };

          # `nix fmt`
          formatter = pkgs.alejandra;

          # `nix flake check`
          checks.pre-commit-hooks = pre-commit-hooks.lib.${system}.run {
            src = nixpkgs.lib.cleanSource ./.;
            hooks = {
              # Nix
              nixfmt.enable = true;
              deadnix.enable = true;
              statix.enable = true;
            };
          };

          # `nix develop`
          devShells.default = pkgs.devshell.mkShell {
            name = "nix-topology";

            commands = [
              {
                package = pkgs.alejandra;
                category = "formatters";
              }
              {
                package = pkgs.deadnix;
                category = "linters";
              }
              {
                package = pkgs.statix;
                category = "linters";
              }
            ];

            devshell.startup.pre-commit.text = self.checks.${system}.pre-commit-hooks.shellHook;
          };
        };
    };
}
