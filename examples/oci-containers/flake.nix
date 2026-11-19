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
    let
      inherit (nixpkgs) lib;
      forAllSystems = lib.genAttrs lib.systems.flakeExposed;
    in
    {
      nixosConfigurations.host1 = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            networking.hostName = "host1";

            systemd.network.enable = true;
            systemd.network.networks.eth0 = {
              matchConfig.Name = "eth0";
              address = [ "192.168.178.100/24" ];
            };

            # Containers whose image is known to the service registry show up as services
            # with the id `oci-<container>`, wherever the image comes from.
            virtualisation.oci-containers.containers = {
              # From lscr.io, with a digest
              jellyfin = {
                image = "lscr.io/linuxserver/jellyfin:10.10.7@sha256:1b5bc95c5ad1b2a4ac9d9fd0d0a1c2a4d6c6d8a0e0e2b4a6c7e8f9a0b1c2d3e4";
                ports = [ "8096:8096" ];
                labels."traefik.http.routers.jellyfin.rule" = "Host(`jellyfin.example.com`)";
              };
              # From ghcr.io
              immich.image = "ghcr.io/immich-app/immich-server:v2.4.0";
              # Several containers of the same service each get a service, named after the
              # container if their names are the same. One from ghcr.io, one from Docker Hub.
              immich-postgres.image = "ghcr.io/immich-app/postgres:14-vectorchord0.4.3";
              paperless-postgres.image = "postgres:17";
              # From an internal mirror of Docker Hub
              web.image = "harbor.example.com/dockerhub/library/nginx:1.27";
              # From a registry with a name nix-topology can't guess, see oci.repos below
              paperless.image = "registry.example.com/mirror/paperless:2.17";
              # Sidecars, hidden below
              immich-redis.image = "docker.io/valkey/valkey:8";
              paperless-redis.image = "redis:7";
              # An app the registry doesn't know, described below
              uptime-kuma = {
                image = "louislam/uptime-kuma:2";
                ports = [ "127.0.0.1:3001:3001" ];
                labels."traefik.http.routers.status.rule" = "Host(`status.example.com`)";
              };
            };

            topology.serviceRegistry = {
              # Add a repository to a built-in entry. The list is added to the
              # built-in one, use `lib.mkForce` to replace it.
              paperless-ngx.oci.repos = [ "registry.example.com/mirror/paperless" ];

              # A hidden entry hides sidecars, and silences the warning about them
              redis = {
                hidden = true;
                oci.repos = [
                  "redis"
                  "valkey"
                ];
              };

              # Describe an app the registry doesn't know. A pattern matches the trailing
              # path components of an image, so `uptime-kuma` matches `louislam/uptime-kuma`
              # from any registry, but not `uptime-kuma-api`.
              uptime-kuma = {
                name = "Uptime Kuma";
                icon = "devices.cloud-server";
                oci = {
                  repos = [ "uptime-kuma" ];
                  # Takes precedence over the extractor's infoFn
                  infoFn = _: "https://status.example.com";
                  # Merged over the extractor's details
                  detailsFn = { container, ... }: { version.text = toString container.image.tag; };
                };
              };
            };

            # Functions for all containers, called with `cfg` (the container's options),
            # `container` (the parsed container) and `config`. This one shows the hosts of
            # traefik's router rules.
            topology.extractors.oci-container.infoFn =
              { container, ... }:
              lib.concatStringsSep " " (
                lib.concatMap (
                  rule:
                  let
                    host = builtins.match "Host\\(`([^`]*)`\\)" rule;
                  in
                  if host == null then [ ] else [ "https://${lib.head host}" ]
                ) (lib.attrValues (lib.filterAttrs (name: _: lib.hasSuffix ".rule" name) container.labels))
              );

            # Replaces the default details (the image and the published ports)
            topology.extractors.oci-container.detailsFn = { container, ... }: {
              image.text = "${container.image.registry}/${container.image.repository}";
              ports = lib.mkIf (container.ports != [ ]) { text = lib.concatStringsSep " " container.ports; };
            };

            # The services can be changed like any other
            topology.self.services.oci-web.name = "Homepage";

            # Containers that don't match any entry are skipped with a warning when the topology
            # is built. To skip them silently:
            # topology.extractors.oci-container.warnUnmatched = false;
          }
          nix-topology.nixosModules.default
        ];
      };

      topology = forAllSystems (
        system:
        import nix-topology {
          pkgs = import nixpkgs {
            inherit system;
            overlays = [ nix-topology.overlays.default ];
          };
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
    };
}
