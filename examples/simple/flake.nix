{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    nix-topology.url = "github:oddlama/nix-topology";
    nix-topology.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-topology,
      flake-utils,
      ...
    }:
    {
      nixosConfigurations.host1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            networking.hostName = "host1";

            # Network interfaces from systemd are detected automatically:
            systemd.network.enable = true;
            systemd.network.networks.eth0 = {
              matchConfig.Name = "eth0";
              address = [ "192.168.178.100/24" ];
            };

            # This node host's a vaultwarden instance, which nix-topology
            # will automatically pick up on
            services.vaultwarden = {
              enable = true;
              config = {
                rocketAddress = "0.0.0.0";
                rocketPort = 8012;
                domain = "https://vault.example.com/";
                # ...
              };
            };

            # We can change our own node's topology settings from here:
            topology.self.interfaces.wg0 = {
              addresses = [ "10.0.0.1" ];
              network = "wg0"; # Use the network we define below
              type = "wireguard"; # changes the icon
            };

            # You can add stuff to the global topology from a nixos configuration, too:
            topology = {
              # Let's say this node acts as a wireguard server, so it would make sense
              # that it defines the related network:
              networks.wg0 = {
                name = "Wireguard network wg0";
                cidrv4 = "10.0.0.0/24";
              };
            };
          }
          nix-topology.nixosModules.default
        ];
      };
      nixosConfigurations.host2 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          (
            { config, ... }:
            {
              networking.hostName = "host2";

              # This host has a wireless connection, as indicated by the wlp prefix
              systemd.network.enable = true;
              systemd.network.networks.wlp3s0 = {
                matchConfig.Name = "wlp3s0";
                address = [ "192.168.178.42/24" ];
              };

              # We can change our own node's topology settings from here:
              topology.self = {
                name = "🥔  Potato host2";
                #         ^^-- utf8 small space, required to not collapse spaces
                hardware.info = "It's running on a potato, i swear";
                interfaces.wg0 = {
                  addresses = [ "10.0.0.2" ];
                  # Rendering virtual connections such as wireguard connections can sometimes
                  # clutter the view. So by hiding them we will only see the connections
                  # in the network centric view
                  renderer.hidePhysicalConnections = true;
                  type = "wireguard"; # changes the icon
                  # No need to add the network wg0 explicitly, it will automatically be propagated via the connection.
                  physicalConnections = [ (config.lib.topology.mkConnection "host1" "wg0") ];
                };
              };
            }
          )
          nix-topology.nixosModules.default
        ];
      };
    }
    // flake-utils.lib.eachDefaultSystem (system: rec {
      pkgs = import nixpkgs {
        inherit system;
        overlays = [ nix-topology.overlays.default ];
      };

      # This is the global topology module.
      topology = import nix-topology {
        inherit pkgs;
        modules = [
          (
            { config, ... }:
            let
              inherit (config.lib.topology) mkInternet mkRouter mkConnection;
            in
            {
              inherit (self) nixosConfigurations;

              # Add a node for the internet
              nodes.internet = mkInternet { connections = mkConnection "router" "wan1"; };

              # Add a router that we use to access the internet
              nodes.router = mkRouter "FritzBox" {
                info = "FRITZ!Box 7520";
                image = ./images/fritzbox.png;
                interfaceGroups = [
                  [
                    "eth1"
                    "eth2"
                    "eth3"
                    "eth4"
                    "wifi"
                  ]
                  [ "wan1" ]
                ];
                connections.eth1 = mkConnection "host1" "eth0";
                connections.wifi = mkConnection "host2" "wlp3s0";
                interfaces.eth1 = {
                  addresses = [ "192.168.178.1" ];
                  network = "home";
                };
              };

              networks.home = {
                name = "Home";
                cidrv4 = "192.168.178.0/24";
              };
            }
          )
        ];
      };
    });
}
