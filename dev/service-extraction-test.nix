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
      networking.hostName = "test-host";
      fileSystems."/" = {
        device = "/dev/null";
        fsType = "ext4";
      };
      boot.loader.grub.device = "/dev/null";
    }
  ];

  eval = nixosSystem {
    inherit system;
    modules = baseModules ++ [
      {
        services.grafana = {
          enable = true;
          settings.server = {
            root_url = "https://grafana.example.com";
            http_addr = "127.0.0.1";
            http_port = 3000;
          };
        };

        services.vaultwarden = {
          enable = true;
          config = {
            domain = "https://vault.example.com";
            rocketAddress = "0.0.0.0";
            rocketPort = 8222;
          };
        };

        services.prometheus = {
          enable = true;
          port = 9090;
        };

        services.openssh.enable = true;
      }
    ];
  };

  services = builtins.deepSeq eval.config.topology.self.services eval.config.topology.self.services;
  serviceNames = lib.sort (a: b: a < b) (lib.attrNames services);

  # Evaluate with no services enabled to detect broken/missing `enabled` functions
  disabledEval = nixosSystem {
    inherit system;
    modules = baseModules;
  };
  disabledServices =
    let
      s = disabledEval.config.topology.self.services;
    in
    builtins.deepSeq s s;
  disabledServiceNames = lib.attrNames (lib.filterAttrs (_: s: s != { }) disabledServices);

  # Build the topology module to verify the full pipeline (services → SVG input)
  topologyEval = import self {
    inherit pkgs;
    modules = [ { nixosConfigurations.test-host = eval; } ];
  };

  nodesConfig = builtins.deepSeq topologyEval.config.nodes topologyEval.config.nodes;
  nodeServices = nodesConfig.test-host.services;
  visibleServices = lib.filterAttrs (_: s: !s.hidden) nodeServices;
  visibleServiceNames = lib.sort (a: b: a < b) (lib.attrNames visibleServices);

  assertions = [
    # No services should appear when nothing is enabled (catches missing/broken `enabled` functions)
    {
      assertion = disabledServiceNames == [ ];
      message = "services appeared without being enabled (broken 'enabled' function): ${toString disabledServiceNames}";
    }
    {
      assertion = services ? grafana;
      message = "expected 'grafana' in extracted services, got: ${toString serviceNames}";
    }
    {
      assertion = services ? vaultwarden;
      message = "expected 'vaultwarden' in extracted services, got: ${toString serviceNames}";
    }
    {
      assertion = services ? prometheus;
      message = "expected 'prometheus' in extracted services, got: ${toString serviceNames}";
    }
    {
      assertion = services ? openssh;
      message = "expected 'openssh' in extracted services, got: ${toString serviceNames}";
    }
    {
      assertion = services.grafana.name == "Grafana";
      message = "expected grafana name 'Grafana', got '${services.grafana.name}'";
    }
    {
      assertion = services.vaultwarden.name == "Vaultwarden";
      message = "expected vaultwarden name 'Vaultwarden', got '${services.vaultwarden.name}'";
    }
    {
      assertion = services.grafana.info == "https://grafana.example.com";
      message = "expected grafana info 'https://grafana.example.com', got '${services.grafana.info}'";
    }
    {
      assertion = services.vaultwarden.info == "https://vault.example.com";
      message = "expected vaultwarden info 'https://vault.example.com', got '${services.vaultwarden.info}'";
    }
    # Verify hidden flag propagation (openssh is hidden by default)
    {
      assertion = services.openssh.hidden;
      message = "expected openssh to be hidden";
    }
    {
      assertion = !services.grafana.hidden;
      message = "expected grafana to not be hidden";
    }
    # Verify topology-level aggregation matches per-host extraction
    {
      assertion = visibleServices ? grafana;
      message = "expected 'grafana' in topology node services, got: ${toString visibleServiceNames}";
    }
    {
      assertion = visibleServices ? vaultwarden;
      message = "expected 'vaultwarden' in topology node services, got: ${toString visibleServiceNames}";
    }
    {
      assertion = visibleServices ? prometheus;
      message = "expected 'prometheus' in topology node services, got: ${toString visibleServiceNames}";
    }
    {
      assertion = !(visibleServices ? openssh);
      message = "expected 'openssh' to NOT be in visible services (it's hidden)";
    }
    # Verify the exact set of visible services (catches unexpected additions)
    {
      assertion =
        visibleServiceNames == [
          "grafana"
          "prometheus"
          "vaultwarden"
        ];
      message = "expected exactly [grafana prometheus vaultwarden] as visible services, got: ${toString visibleServiceNames}";
    }
  ];

  failedAssertions = builtins.filter (a: !a.assertion) assertions;
  failureMessages = map (a: a.message) failedAssertions;
in
if failedAssertions != [ ] then
  throw "Service extraction test failed:\n${lib.concatStringsSep "\n" failureMessages}"
else
  pkgs.runCommandLocal "service-extraction-test" { } ''
    echo "Service extraction test passed"
    echo "Extracted services: ${toString serviceNames}"
    echo "Visible services in topology: ${toString visibleServiceNames}"
    echo "ok" > $out
  ''
