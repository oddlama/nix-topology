{
  description = "🍁 Generate infrastructure and network diagrams directly from your NixOS configurations";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    systems,
    treefmt-nix,
    devshell,
    ...
  } @ inputs: let
    forAllSystems = nixpkgs.lib.genAttrs (import systems);

    treefmtEval = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in
        treefmt-nix.lib.evalModule pkgs ./treefmt.nix
    );
  in {
    flakeModule = ./flake-module.nix;

    # Expose NixOS module
    nixosModules = {
      default = self.nixosModules.topology;
      topology = ./nixos/module.nix;
    };

    # A nixpkgs overlay that adds the parametrized builder as a package
    overlays = {
      default = self.overlays.topology;
      topology = import ./pkgs/default.nix;
    };

    # `nix fmt`
    formatter = forAllSystems (system: treefmtEval.${system}.config.build.wrapper);

    # `nix flake check`
    checks = forAllSystems (system: {
      formatting = treefmtEval.${system}.config.build.check self;
    });

    packages = forAllSystems (
      system: let
        pkgs = nixpkgs.legacyPackages.${system};
      in {
        docs = pkgs.callPackage ./pkgs/docs.nix {
          flakeInputs = inputs;
          flakeOutputs = self;
        };
      }
    );

    devShells = forAllSystems (
      system: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            self.overlays.default
            devshell.overlays.default
          ];
        };
      in
        import ./shell.nix {inherit pkgs;}
    );
  };
}
