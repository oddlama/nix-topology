{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-topology,
      ...
    }:
    {
      nixosConfigurations.host1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (
            { config, ... }:
            {
              networking.hostName = "host1";

              # Network interfaces from systemd are detected automatically:
              systemd.network.enable = true;
              systemd.network.networks.eth0 = {
                matchConfig.Name = "eth0";
              };

              # This node hosts a Jellyfin container
              virtualisation.oci-containers.containers.jellyfin = {
                image = "lscr.io/linuxserver/jellyfin:10.10.3";
                labels = {
                  "traefik.http.routers.jellyfin.rule" = "Host(`jellyfin.example.com`)";
                };
              };

              # Use a built-in function to extract the host information from the container labels
              topology.extractors.oci-container.infoFn =
                config.topology.extractors.oci-container.lib.traefikHostInfoFn;

              # Define a custom details function to extract and show additional information
              topology.extractors.oci-container.detailsFn = c: { image.text = c.image; };
            }
          )
          nix-topology.nixosModules.default
        ];
      };
    }
    // (
      let
        forAllSystems = nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed;
      in
      {
        topology = forAllSystems (
          system:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ nix-topology.overlays.default ];
            };
          in
          import nix-topology {
            inherit pkgs;
            modules = [
              (
                { config, ... }:
                let
                  inherit (config.lib.topology) mkInternet mkConnection;
                in
                {
                  inherit (self) nixosConfigurations;
                  nodes.internet = mkInternet { connections = mkConnection "host1" "eth0"; };
                }
              )
            ];
          }
        );
      }
    );
}
