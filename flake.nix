{
  description = "🍁 Generate infrastructure and network diagrams directly from your NixOS configurations";

  inputs = {
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };

    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.flake-utils.follows = "flake-utils";
    };
  };

  outputs = {
    self,
    devshell,
    flake-utils,
    nixpkgs,
    pre-commit-hooks,
    ...
  } @ inputs:
    {
      flakeModule = ./flake-module.nix;

      # Expose NixOS module
      nixosModules.topology = ./nixos/module.nix;
      nixosModules.default = self.nixosModules.topology;

      # A nixpkgs overlay that adds the parametrized builder as a package
      overlays.default = self.overlays.topology;
      overlays.topology = import ./pkgs/default.nix;
    }
    // flake-utils.lib.eachDefaultSystem (system: rec {
      pkgs = import nixpkgs {
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

      # `nix flake check`
      checks.pre-commit-hooks = pre-commit-hooks.lib.${system}.run {
        src = nixpkgs.lib.cleanSource ./.;
        hooks = {
          # Nix
          alejandra.enable = true;
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
            help = "Format nix code";
          }
          {
            package = pkgs.statix;
            help = "Lint nix code";
          }
          {
            package = pkgs.deadnix;
            help = "Find unused expressions in nix code";
          }
        ];

        devshell.startup.pre-commit.text = self.checks.${system}.pre-commit-hooks.shellHook;
      };

      # `nix fmt`
      formatter = pkgs.alejandra;
    });
}
