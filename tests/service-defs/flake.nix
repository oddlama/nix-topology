{
  description = "Test flake to verify all service definitions evaluate correctly";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-topology.url = "../..";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-topology,
      ...
    }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-topology.overlays.default ];
        config.allowUnfree = true;
      };
    in
    {
      nixosConfigurations.test-services = nixpkgs.lib.nixosSystem {
        inherit system;
        modules = [
          nix-topology.nixosModules.default
          ./test-module.nix
        ];
      };

      topology.${system} =
        let
          topologyPkgs = import nixpkgs {
            inherit system;
            overlays = [ nix-topology.overlays.default ];
          };
        in
        import nix-topology {
          pkgs = topologyPkgs;
          modules = [ { inherit (self) nixosConfigurations; } ];
        };

      # Evaluation check - forces topology to be evaluated
      # This derivation depends on the actual topology output, forcing full evaluation
      checks.${system}.service-defs =
        let
          topologyOutput = self.topology.${system}.config.output;
        in
        pkgs.runCommand "check-service-defs"
          {
            # Reference the topology output to force evaluation
            inherit topologyOutput;
          }
          ''
            echo "Topology output: $topologyOutput"
            ls -la "$topologyOutput"
            touch $out
          '';
    };
}
