{
  self,
  pkgs,
  system,
}:
let
  inherit (pkgs) lib;
  nixosSystem = import "${pkgs.path}/nixos/lib/eval-config.nix";

  baseModules = [
    self.nixosModules.topology
    {
      fileSystems."/" = {
        device = "/dev/null";
        fsType = "ext4";
      };
      boot.loader.grub.device = "/dev/null";
    }
  ];

  # A shared module that overrides the registry for all nodes that import it
  sharedRegistryOverride = {
    topology.serviceRegistry.grafana.name = "Shared Grafana";
  };

  # --- Scenario 1: Per-node override ---
  # node-a overrides grafana's name just for itself
  nodeA = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      {
        networking.hostName = "node-a";
        services.grafana.enable = true;
        topology.serviceRegistry.grafana.name = "Node-A Grafana";
      }
    ];
  };

  # node-b uses the default registry (no override)
  nodeB = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      {
        networking.hostName = "node-b";
        services.grafana.enable = true;
      }
    ];
  };

  perNodeEval = import self {
    inherit pkgs;
    modules = [
      {
        nixosConfigurations = {
          node-a = nodeA;
          node-b = nodeB;
        };
      }
    ];
  };

  perNodeNodes = builtins.deepSeq perNodeEval.config.nodes perNodeEval.config.nodes;

  # --- Scenario 2: Shared module override (applies to all nodes) ---
  # Both nodes import the same shared override module
  nodeC = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      sharedRegistryOverride
      {
        networking.hostName = "node-c";
        services.grafana.enable = true;
      }
    ];
  };

  nodeD = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      sharedRegistryOverride
      {
        networking.hostName = "node-d";
        services.grafana.enable = true;
      }
    ];
  };

  sharedEval = import self {
    inherit pkgs;
    modules = [
      {
        nixosConfigurations = {
          node-c = nodeC;
          node-d = nodeD;
        };
      }
    ];
  };

  sharedNodes = builtins.deepSeq sharedEval.config.nodes sharedEval.config.nodes;

  # --- Scenario 3: Overriding a single `nixos.*` field ---
  nodeE = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      {
        networking.hostName = "node-e";
        services.grafana.enable = true;
        topology.serviceRegistry.grafana.nixos.infoFn = _: "custom-info";
      }
    ];
  };
  nodeEServices = builtins.deepSeq nodeE.config.topology.self.services nodeE.config.topology.self.services;

  # --- Scenario 4: Overriding `info` of an extracted service ---
  nodeF = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      {
        networking.hostName = "node-f";
        services.prometheus.enable = true;
        topology.self.services.prometheus.info = "https://prom.example.com";
      }
    ];
  };
  nodeFServices = builtins.deepSeq nodeF.config.topology.self.services nodeF.config.topology.self.services;

  # --- Scenario 5: A container's override must not affect its host ---
  nodeH = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      {
        networking.hostName = "node-h";
        services.grafana.enable = true;
        containers.guest = {
          autoStart = true;
          config = {
            imports = [ self.nixosModules.topology ];
            networking.hostName = "guest";
            services.grafana.enable = true;
            topology.serviceRegistry.grafana.name = "Guest Grafana";
          };
        };
      }
    ];
  };
  nodeHNodes = builtins.deepSeq nodeH.config.topology.nodes nodeH.config.topology.nodes;

  # --- Scenario 6: serviceId on a non-NixOS node, without any NixOS hosts ---
  noHostsEval = import self {
    inherit pkgs;
    modules = [
      {
        nodes.router = {
          deviceType = "router";
          services.dns.serviceId = "adguardhome";
        };
      }
    ];
  };
  # A registry entry without a name, on a non-NixOS node
  namelessEval = import self {
    inherit pkgs;
    modules = [
      {
        serviceRegistry.nameless.icon = "services.grafana";
        nodes.router = {
          deviceType = "router";
          services.db.serviceId = "mysql";
          services.app.serviceId = "nameless";
        };
      }
    ];
  };
  namelessServices = namelessEval.config.nodes.router.services;
  noHostsFailed = builtins.filter (a: !a.assertion) noHostsEval.config.assertions;

  # --- Scenario 7: Dynamic icon (iconFn) in the rendered topology ---
  nodeM = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      {
        networking.hostName = "node-m";
        services.mysql = {
          enable = true;
          package = pkgs.mariadb;
        };
      }
    ];
  };
  dynamicIconEval = import self {
    inherit pkgs;
    modules = [ { nixosConfigurations.node-m = nodeM; } ];
  };
  dynamicIcon = builtins.tryEval dynamicIconEval.config.nodes.node-m.services.mysql.icon;

  # --- Scenario 8: Host registries stay local to their host ---
  nodeR = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      {
        networking.hostName = "node-r";
        services.grafana.enable = true;
        topology.serviceRegistry.grafana.name = "Node-R Grafana";
        # Only defined in this host's config
        topology.serviceRegistry.myapp = {
          name = "My App";
          nixos = {
            path = "networking";
            enabled = _: true;
          };
        };
        topology.serviceRegistry.nameless.nixos = {
          path = "networking";
          enabled = _: true;
        };
      }
    ];
  };
  hostLocalEval = import self {
    inherit pkgs;
    modules = [
      {
        nixosConfigurations.node-r = nodeR;
        nodes.nas = {
          deviceType = "device";
          services.monitoring.serviceId = "grafana";
          services.typo.serviceId = "grafanna";
        };
      }
    ];
  };
  hostLocalNodes = hostLocalEval.config.nodes;
  hostLocalFailed = map (a: a.message) (
    builtins.filter (a: !a.assertion) hostLocalEval.config.assertions
  );

  # --- Scenario 10: A manually added serviceId on a NixOS host uses that host's registry ---
  nodeS = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      {
        networking.hostName = "node-s";
        topology.serviceRegistry.grafana.name = "Node-S Grafana";
        # Only defined in this host's config, not extracted
        topology.serviceRegistry.myapp = {
          name = "My App";
          icon = "services.grafana";
        };
        topology.self.services.db.serviceId = "grafana";
        topology.self.services.app.serviceId = "myapp";
        topology.self.services.typo.serviceId = "grafanna";
      }
    ];
  };
  manualHostServices = nodeS.config.topology.self.services;
  manualEval = import self {
    inherit pkgs;
    modules = [ { nixosConfigurations.node-s = nodeS; } ];
  };
  manualTopServices = manualEval.config.nodes.node-s.services;
  manualFailed = map (a: a.message) (builtins.filter (a: !a.assertion) manualEval.config.assertions);
  nameIcon = s: { inherit (s) name icon; };
  manualExpected = {
    db = {
      name = "Node-S Grafana";
      icon = "services.grafana";
    };
    app = {
      name = "My App";
      icon = "services.grafana";
    };
  };
  manualGot = services: lib.mapAttrs (n: _: nameIcon services.${n}) manualExpected;

  # --- Scenario 9: Function fields are stored as-is and must be functions ---
  grafanaWith =
    modules:
    nixosSystem {
      inherit system;
      modules =
        baseModules
        ++ [
          {
            networking.hostName = "node-f";
            services.grafana.enable = true;
          }
        ]
        ++ modules;
    };
  setInfoFn = value: { topology.serviceRegistry.grafana.nixos.infoFn = value; };
  infoFnOf = eval: builtins.tryEval eval.config.topology.serviceRegistry.grafana.nixos.infoFn;
  # A returned mkIf must not evaluate its content when the condition is false
  lazyInfo =
    builtins.tryEval
      (grafanaWith [ (setInfoFn (_: lib.mkIf false (throw "evaluated inactive mkIf"))) ])
      .config.topology.self.services.grafana.info;
  nonFunctionInfoFn = infoFnOf (grafanaWith [ (setInfoFn "https://grafana.example.com") ]);
  twoInfoFns = infoFnOf (grafanaWith [
    (setInfoFn (_: "one"))
    (setInfoFn (_: "two"))
  ]);

  # --- Scenario 11: Home Assistant settings that newer nixpkgs don't default ---
  haDetails = (import ../nixos/service-defs/home-assistant.nix { inherit lib; }).nixos.detailsFn;
  haListen = config: (haDetails { inherit config; }).listen.text;

  assertions = [
    # Per-node: node-a has custom name, node-b has default
    {
      assertion = perNodeNodes.node-a.services.grafana.name == "Node-A Grafana";
      message = "per-node override: node-a should have 'Node-A Grafana', got '${perNodeNodes.node-a.services.grafana.name}'";
    }
    {
      assertion = perNodeNodes.node-b.services.grafana.name == "Grafana";
      message = "per-node override: node-b should have default 'Grafana', got '${perNodeNodes.node-b.services.grafana.name}'";
    }
    # Shared module: both nodes see the shared override
    {
      assertion = sharedNodes.node-c.services.grafana.name == "Shared Grafana";
      message = "shared override: node-c should have 'Shared Grafana', got '${sharedNodes.node-c.services.grafana.name}'";
    }
    {
      assertion = sharedNodes.node-d.services.grafana.name == "Shared Grafana";
      message = "shared override: node-d should have 'Shared Grafana', got '${sharedNodes.node-d.services.grafana.name}'";
    }
    # Partial nixos.* override keeps the rest of the entry
    {
      assertion = nodeEServices ? grafana && nodeEServices.grafana.info == "custom-info";
      message = "partial nixos override: expected grafana with info 'custom-info', got services: ${toString (lib.attrNames nodeEServices)}";
    }
    # User-set info is used as-is
    {
      assertion = nodeFServices.prometheus.info == "https://prom.example.com";
      message = "info override: expected 'https://prom.example.com', got ${builtins.toJSON nodeFServices.prometheus.info}";
    }
    # Container override applies to the container only
    {
      assertion = nodeHNodes.node-h.services.grafana.name == "Grafana";
      message = "container override: host should keep 'Grafana', got '${nodeHNodes.node-h.services.grafana.name}'";
    }
    {
      assertion = nodeHNodes.guest.services.grafana.name == "Guest Grafana";
      message = "container override: container should have 'Guest Grafana', got '${nodeHNodes.guest.services.grafana.name}'";
    }
    # Built-in registry entries are available without NixOS hosts
    {
      assertion =
        noHostsFailed == [ ] && noHostsEval.config.nodes.router.services.dns.name == "AdGuard Home";
      message = "no NixOS hosts: serviceId 'adguardhome' should resolve, failed assertions: ${
        toString (map (a: a.message) noHostsFailed)
      }";
    }
    # Missing registry names fall back to the service's id
    {
      assertion = namelessServices.db.name == "MySQL" && namelessServices.app.name == "app";
      message = "nameless registry entries: expected 'MySQL' and 'app', got '${namelessServices.db.name}' and '${namelessServices.app.name}'";
    }
    {
      assertion = hostLocalNodes.node-r.services.nameless.name == "nameless";
      message = "nameless extracted service: expected 'nameless', got '${hostLocalNodes.node-r.services.nameless.name}'";
    }
    {
      assertion = dynamicIcon.success && dynamicIcon.value == "services.mariadb";
      message = "dynamic icon: expected 'services.mariadb' for mysql with mariadb in the topology, got ${builtins.toJSON dynamicIcon}";
    }
    # A host's override doesn't apply to services on other nodes
    {
      assertion = hostLocalNodes.nas.services.monitoring.name == "Grafana";
      message = "host-local registry: expected 'Grafana' on nas, got '${hostLocalNodes.nas.services.monitoring.name}'";
    }
    # Host-only entries work on that host, typos on non-NixOS nodes are reported
    {
      assertion =
        hostLocalNodes.node-r.services.grafana.name == "Node-R Grafana"
        && hostLocalNodes.node-r.services.myapp.name == "My App"
        &&
          hostLocalFailed == [
            "serviceId 'grafanna' for nodes.nas.services.typo is not defined in topology.serviceRegistry"
          ];
      message = "host-local registry: unexpected failed assertions: ${toString hostLocalFailed}";
    }
    # A manually added serviceId resolves against the host's registry, on the host and in the topology
    {
      assertion = manualGot manualHostServices == manualExpected;
      message = "manual serviceId on host: expected ${builtins.toJSON manualExpected}, got ${builtins.toJSON (manualGot manualHostServices)}";
    }
    {
      assertion = manualGot manualTopServices == manualExpected;
      message = "manual serviceId in topology: expected ${builtins.toJSON manualExpected}, got ${builtins.toJSON (manualGot manualTopServices)}";
    }
    {
      assertion =
        manualFailed == [
          "serviceId 'grafanna' for nodes.node-s.services.typo is not defined in topology.serviceRegistry"
        ];
      message = "manual serviceId on host: unexpected failed assertions: ${toString manualFailed}";
    }
    {
      assertion = lazyInfo.success && lazyInfo.value == "";
      message = "function fields: a returned mkIf false must not be evaluated, got ${builtins.toJSON lazyInfo}";
    }
    {
      assertion = !nonFunctionInfoFn.success && !twoInfoFns.success;
      message = "function fields: non-function values and conflicting definitions must be rejected";
    }
    {
      assertion =
        haListen { http = { }; } == "0.0.0.0:8123 :::8123"
        && haListen { http.server_host = "::1"; } == "::1:8123";
      message = "home-assistant: expected Home Assistant's default listen addresses without http.server_host/server_port";
    }
  ];

  failedAssertions = builtins.filter (a: !a.assertion) assertions;
  failureMessages = map (a: a.message) failedAssertions;
in
if failedAssertions != [ ] then
  throw "Service registry override test failed:\n${lib.concatStringsSep "\n" failureMessages}"
else
  pkgs.runCommandLocal "service-registry-override-test" { } ''
    echo "Service registry override test passed"
    echo "  - Per-node override applies only to that node: OK"
    echo "  - Shared module override applies to all nodes: OK"
    echo "  - Partial nixos.* override keeps the registry entry: OK"
    echo "  - User-set info is used as-is: OK"
    echo "  - Container override doesn't affect its host: OK"
    echo "  - Built-in registry entries are available without NixOS hosts: OK"
    echo "  - Registry entries without a name fall back to the service id: OK"
    echo "  - Dynamic icon (iconFn) is used in the topology: OK"
    echo "  - Host registries stay local to their host: OK"
    echo "  - Manual serviceId on a NixOS host uses the host's registry, typos are reported: OK"
    echo "  - Function fields are stored as-is and must be functions: OK"
    echo "  - Home Assistant without http.server_host/server_port: OK"
    echo "ok" > $out
  ''
