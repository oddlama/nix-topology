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
    echo "ok" > $out
  ''
