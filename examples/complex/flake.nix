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
          {
            networking.hostName = "host1";

            # Network interfaces from systemd are detected automatically:
            systemd.network.enable = true;
            systemd.network.networks.wan = {
              matchConfig.Name = "wan";
              address = [ "192.168.178.100/24" ];
            };
            systemd.network.networks.lan = {
              matchConfig.Name = "lan";
              address = [ "192.168.1.1/24" ];
            };

            # Hosts a DHCP server with kea, this will become a network automatically
            services.kea.dhcp4 = {
              # ... (skipped unnecessary options for brevity)
              enable = true;
              settings = {
                interfaces-config.interfaces = [ "lan" ];
                subnet4 = [
                  {
                    interface = "lan-self";
                    subnet = "192.168.1.0/24";
                  }
                ];
              };
            };

            virtualisation.oci-containers.backend = "docker";
            virtualisation.oci-containers.containers = {
              test = {
                image = "test/test:latest";
              };
            };

            # We can change our own node's topology settings from here:
            topology.self.name = "🧱  Small Firewall";
            topology.self.interfaces.wg0 = {
              addresses = [ "10.0.0.1" ];
              network = "wg0"; # Use the network we define below
              virtual = true; # doesn't change the immediate render yet, but makes the network-centric view a little more readable
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
              systemd.network.networks.eth0 = {
                matchConfig.Name = "eth0";
                address = [ "192.168.1.100/24" ];
              };

              # Containers will automatically be rendered if they import the topology module!
              containers.vaultwarden.macvlans = [ "vm-vaultwarden" ];
              containers.vaultwarden.config = {
                imports = [ nix-topology.nixosModules.default ];
                networking.hostName = "host2-vaultwarden";
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
              };

              services.vaultwarden = {
                enable = true;
                config = {
                  rocketAddress = "0.0.0.0";
                  rocketPort = 8012;
                  domain = "https://anothervault.example.com/";
                  # ...
                };
              };

              virtualisation.oci-containers.backend = "podman";
              virtualisation.oci-containers.containers = {
                test = {
                  image = "test/test@digest";

                  ports = [ "4242:80" ];

                  volumes = [ "/test:/mnt" ];

                };
              };

              containers.test.config = {
                imports = [ nix-topology.nixosModules.default ];
                networking.hostName = "host2-test";
              };

              # We can change our own node's topology settings from here:
              topology.self = {
                name = "☄️  Powerful host2";
                hardware.info = "2U Server with loads of RAM";
                interfaces.wg0 = {
                  addresses = [ "10.0.0.2" ];
                  # Rendering virtual connections such as wireguard connections can sometimes
                  # clutter the view. So by hiding them we will only see the connections
                  # in the network centric view
                  renderer.hidePhysicalConnections = true;
                  virtual = true; # doesn't change the immediate render yet, but makes the network-centric view a little more readable
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
      nixosConfigurations.desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            networking.hostName = "desktop";

            # This host has a wireless connection, as indicated by the wlp prefix
            systemd.network.enable = true;
            systemd.network.networks.eth0 = {
              matchConfig.Name = "eth0";
              address = [ "192.168.1.123/24" ];
            };

            topology.self = {
              name = "🖥️ Desktop";
              hardware.info = "AMD Ryzen 7850X, 64GB RAM";
            };
          }
          nix-topology.nixosModules.default
        ];
      };
      nixosConfigurations.laptop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            networking.hostName = "laptop";

            # This host has a wireless connection, as indicated by the wlp prefix
            systemd.network.enable = true;
            systemd.network.networks.eth0 = {
              matchConfig.Name = "eth0";
              address = [ "192.168.1.142/24" ];
            };
            systemd.network.networks.wlp1s1 = {
              matchConfig.Name = "wlp1s1";
            };

            topology.self = {
              name = "💻  Laptop";
              hardware.info = "Framework 16";
            };
          }
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
          # This is the global topology module.
          import nix-topology {
            inherit pkgs;
            modules = [
              (
                { config, ... }:
                let
                  inherit (config.lib.topology)
                    mkInternet
                    mkRouter
                    mkSwitch
                    mkConnection
                    ;
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
                      ]
                      [ "wan1" ]
                    ];
                    connections.eth1 = mkConnection "host1" "wan";
                    interfaces.eth1 = {
                      addresses = [ "192.168.178.1" ];
                      network = "home-fritzbox";
                    };
                  };

                  networks.home-fritzbox = {
                    name = "Home Fritzbox";
                    cidrv4 = "192.168.178.0/24";
                  };

                  networks.host1-kea.name = "Home LAN";
                  nodes.switch-main = mkSwitch "Main Switch" {
                    info = "D-Link DGS-1016D";
                    image = ./images/dlink-dgs1016d.png;
                    interfaceGroups = [
                      [
                        "eth1"
                        "eth2"
                        "eth3"
                        "eth4"
                        "eth5"
                        "eth6"
                      ]
                    ];
                    connections.eth1 = mkConnection "host1" "lan";
                    connections.eth2 = mkConnection "host2" "eth0";
                    connections.eth3 = mkConnection "switch-livingroom" "eth1";
                  };

                  nodes.switch-livingroom = mkSwitch "Livingroom Switch" {
                    info = "D-Link DGS-105";
                    image = ./images/dlink-dgs105.png;
                    interfaceGroups = [
                      [
                        "eth1"
                        "eth2"
                        "eth3"
                        "eth4"
                        "eth5"
                      ]
                    ];
                    connections.eth2 = mkConnection "desktop" "eth0";
                    connections.eth3 = mkConnection "laptop" "eth0";
                  };
                }
              )
            ];
          }
        );
      }
    );
}
