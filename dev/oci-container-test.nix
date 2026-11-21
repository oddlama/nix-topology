{
  self,
  pkgs,
  system,
}:
let
  inherit (pkgs) lib;
  nixosSystem = import "${pkgs.path}/nixos/lib/eval-config.nix";

  baseModule = {
    fileSystems."/" = {
      device = "/dev/null";
      fsType = "ext4";
    };
    boot.loader.grub.device = "/dev/null";
  };
  mkHost =
    hostName: modules:
    nixosSystem {
      inherit system;
      modules = [
        self.nixosModules.topology
        baseModule
        { networking.hostName = hostName; }
      ]
      ++ modules;
    };
  servicesOf =
    host:
    let
      s = host.config.topology.self.services;
    in
    builtins.deepSeq s s;
  unmatchedOf = host: host.config.topology.extractors.oci-container.unmatched;
  detailTexts = service: lib.mapAttrs (_: d: d.text) service.details;

  # --- Backends, duplicates, unmatched containers and default details ---
  mkBackendHost =
    backend:
    mkHost "host-${backend}" [
      {
        virtualisation.oci-containers = {
          inherit backend;
          containers = {
            jellyfin = {
              image = "lscr.io/linuxserver/jellyfin:10.10.3@sha256:${lib.fixedWidthString 64 "a" ""}";
              ports = [
                "8096:8096"
                "127.0.0.1:8920:8920"
              ];
            };
            db-app = {
              image = "postgres:16";
            };
            db-other = {
              image = "docker.io/library/postgres:17-alpine";
            };
            mystery.image = "ghcr.io/example/mystery-app:1.0";
          };
        };
      }
    ];
  docker = mkBackendHost "docker";
  podman = mkBackendHost "podman";
  dockerServices = servicesOf docker;
  podmanServices = servicesOf podman;

  # --- Registry functions, extractor-wide functions and overrides ---
  functions = mkHost "host-functions" [
    {
      virtualisation.oci-containers.containers = {
        grafana = {
          image = "grafana/grafana:11.0.0";
          labels."traefik.http.routers.grafana.rule" = "Host(`grafana.example.com`)";
          environment.GF_SERVER_ROOT_URL = "https://grafana.example.com";
        };
        jellyfin.image = "jellyfin/jellyfin";
        overridden.image = "jellyfin/jellyfin";
      };
      topology.serviceRegistry.grafana.oci = {
        nameFn = { container, ... }: "Grafana on ${container.backend}";
        iconFn = _: "services.prometheus";
        infoFn = { cfg, ... }: cfg.environment.GF_SERVER_ROOT_URL;
        detailsFn = { container, ... }: {
          image.text = container.image.repository;
          backend.text = container.backend;
        };
      };
      # Returns nothing, so the extractor's infoFn is used
      topology.serviceRegistry.jellyfin.oci.infoFn = _: null;
      topology.extractors.oci-container = {
        infoFn = { container, ... }: "info of ${container.name}";
        detailsFn = { container, ... }: { tag.text = toString container.image.tag; };
      };
      topology.self.services.oci-overridden = {
        name = "My Jellyfin";
        info = "https://jf.example.com";
      };
    }
  ];
  functionServices = servicesOf functions;

  # --- Adding repos, replacing them and hiding sidecars ---
  repos = mkHost "host-repos" [
    {
      virtualisation.oci-containers.containers = {
        mirrored.image = "registry.lan/mirror/jf:latest";
        pg.image = "postgres:16";
        renamed.image = "tensorchord/pgvecto-rs:pg16";
        cache.image = "redis:7";
      };
      # Adds to the built-in repos
      topology.serviceRegistry.jellyfin.oci.repos = [ "registry.lan/mirror/jf" ];
      # Replaces them
      topology.serviceRegistry.postgresql.oci.repos = lib.mkForce [ "pgvecto-rs" ];
      # A hidden entry silences a sidecar
      topology.serviceRegistry.redis = {
        hidden = true;
        oci.repos = [ "redis" ];
      };
      # Functions returning null mean no info, like on the NixOS side
      topology.serviceRegistry.postgresql.oci.infoFn = { container, ... }: container.labels.info or null;
      topology.extractors.oci-container.infoFn = _: null;
    }
  ];
  repoServices = servicesOf repos;

  # --- Disabled extractor ---
  disabled = mkHost "host-disabled" [
    {
      virtualisation.oci-containers.containers.jellyfin.image = "jellyfin/jellyfin";
      topology.extractors.oci-container.enable = false;
    }
  ];

  # --- Without containers ---
  empty = mkHost "host-empty" [ ];

  # --- A NixOS service and a container of the same entry, and a nested container ---
  mixed = mkHost "host-mixed" [
    {
      services.grafana.enable = true;
      virtualisation.oci-containers.containers.grafana.image = "grafana/grafana";
      containers.guest = {
        autoStart = true;
        config = {
          imports = [ self.nixosModules.topology ];
          networking.hostName = "guest";
          virtualisation.oci-containers.containers.inner.image = "jellyfin/jellyfin";
        };
      };
    }
  ];

  topologyEval = import self {
    inherit pkgs;
    modules = [ { nixosConfigurations = { inherit docker functions mixed; }; } ];
  };
  topologyNodes = builtins.deepSeq topologyEval.config.nodes topologyEval.config.nodes;
  topologyFailed = map (a: a.message) (
    builtins.filter (a: !a.assertion) topologyEval.config.assertions
  );

  pick = attrs: s: lib.genAttrs attrs (a: s.${a});

  expectEq = what: got: want: {
    assertion = got == want;
    message = "${what}: expected ${builtins.toJSON want}, got ${builtins.toJSON got}";
  };

  assertions = [
    # One service per container, also for containers of the same entry
    (expectEq "docker services" (lib.attrNames dockerServices) [
      "oci-db-app"
      "oci-db-other"
      "oci-jellyfin"
    ])
    (expectEq "podman services" (lib.attrNames podmanServices) (lib.attrNames dockerServices))
    (expectEq "jellyfin service"
      (pick [ "serviceId" "source" "name" "icon" "hidden" "info" ] dockerServices.oci-jellyfin)
      {
        serviceId = "jellyfin";
        source = "oci";
        name = "Jellyfin";
        icon = "services.jellyfin";
        hidden = false;
        info = "";
      }
    )
    (expectEq "default details" (detailTexts dockerServices.oci-jellyfin) {
      image = "lscr.io/linuxserver/jellyfin:10.10.3";
      ports = "8096:8096 127.0.0.1:8920:8920";
    })
    (expectEq "default details without ports" (detailTexts dockerServices.oci-db-app) {
      image = "postgres:16";
    })
    (expectEq "names of containers of the same entry"
      (map (s: s.name) [
        dockerServices.oci-db-app
        dockerServices.oci-db-other
      ])
      [
        "PostgreSQL (db-app)"
        "PostgreSQL (db-other)"
      ]
    )
    (expectEq "unmatched containers" (unmatchedOf docker) [
      {
        name = "mystery";
        image = "ghcr.io/example/mystery-app:1.0";
      }
    ])

    # Registry functions win over the extractor's, details are merged
    (expectEq "registry functions" (pick [ "name" "icon" "info" ] functionServices.oci-grafana) {
      name = "Grafana on podman";
      icon = "services.prometheus";
      info = "https://grafana.example.com";
    })
    (expectEq "merged details" (detailTexts functionServices.oci-grafana) {
      image = "grafana/grafana";
      backend = "podman";
      tag = "11.0.0";
    })
    (expectEq "extractor functions"
      {
        inherit (functionServices.oci-jellyfin) info;
        details = detailTexts functionServices.oci-jellyfin;
      }
      {
        info = "info of jellyfin";
        details.tag = "";
      }
    )
    (expectEq "overridden service" (pick [ "name" "info" ] functionServices.oci-overridden) {
      name = "My Jellyfin";
      info = "https://jf.example.com";
    })

    # Repos are added to the built-in ones, mkForce replaces them
    (expectEq "added repo" repoServices.oci-mirrored.serviceId "jellyfin")
    (expectEq "replaced repos" (repoServices ? oci-pg) false)
    (expectEq "replacement repo" repoServices.oci-renamed.serviceId "postgresql")
    (expectEq "hidden sidecar" (pick [ "serviceId" "hidden" ] repoServices.oci-cache) {
      serviceId = "redis";
      hidden = true;
    })
    (expectEq "unmatched with replaced repos" (map (c: c.name) (unmatchedOf repos)) [ "pg" ])
    (expectEq "infoFns returning null" repoServices.oci-renamed.info "")

    (expectEq "disabled extractor" (lib.attrNames (servicesOf disabled)) [ ])
    (expectEq "no containers" (lib.attrNames (servicesOf empty)) [ ])

    # In the topology
    (expectEq "NixOS service and container side by side"
      (lib.mapAttrs (_: s: { inherit (s) serviceId source; }) (
        lib.filterAttrs (n: _: n == "grafana" || n == "oci-grafana") topologyNodes.host-mixed.services
      ))
      {
        grafana = {
          serviceId = "grafana";
          source = "nixos";
        };
        oci-grafana = {
          serviceId = "grafana";
          source = "oci";
        };
      }
    )
    (expectEq "nested container's service on the guest node"
      {
        guest = topologyNodes.guest.services.oci-inner.name or null;
        host = topologyNodes.host-mixed.services ? oci-inner;
      }
      {
        guest = "Jellyfin";
        host = false;
      }
    )
    (expectEq "topology services of the docker host" (lib.attrNames topologyNodes.host-docker.services)
      [
        "oci-db-app"
        "oci-db-other"
        "oci-jellyfin"
      ]
    )
    (expectEq "topology assertions" topologyFailed [ ])
  ];

  failedAssertions = builtins.filter (a: !a.assertion) assertions;
  failureMessages = map (a: a.message) failedAssertions;
in
if failedAssertions != [ ] then
  throw "OCI container extractor test failed:\n${lib.concatStringsSep "\n" failureMessages}"
else
  pkgs.runCommandLocal "oci-container-test" { } ''
    echo "OCI container extractor test passed"
    echo "  - docker and podman backends, one service per container: OK"
    echo "  - unmatched containers are reported and get no service: OK"
    echo "  - registry and extractor functions, per-service overrides: OK"
    echo "  - added and replaced repos, hidden sidecars: OK"
    echo "  - disabled extractor and hosts without containers: OK"
    echo "  - NixOS services side by side, nested containers: OK"
    echo "ok" > $out
  ''
