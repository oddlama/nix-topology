{
  self,
  pkgs,
  system,
}:
let
  nixosSystem = import "${pkgs.path}/nixos/lib/eval-config.nix";

  eval = nixosSystem {
    inherit system;
    modules = [
      self.nixosModules.topology
      {
        networking.hostName = "svg-test-host";
        fileSystems."/" = {
          device = "/dev/null";
          fsType = "ext4";
        };
        boot.loader.grub.device = "/dev/null";

        services.grafana = {
          enable = true;
          settings.server = {
            root_url = "https://grafana.example.com";
            http_addr = "127.0.0.1";
            http_port = 3000;
          };
        };

        services.prometheus = {
          enable = true;
          port = 9090;
        };

        # Containers matched by the oci-container extractor
        virtualisation.oci-containers.containers.jellyfin = {
          image = "lscr.io/linuxserver/jellyfin:10.10.3";
          ports = [ "8096:8096" ];
        };
        topology.serviceRegistry.jellyfin.oci.repos = [ "jellyfin" ];

        # Two services sharing a serviceId, both must be listed in the services overview
        services.restic.backups = {
          alpha = {
            repository = "/mnt/alpha";
            passwordFile = "/run/secrets/restic";
            paths = [ "/srv/alpha" ];
          };
          bravo = {
            repository = "/mnt/bravo";
            passwordFile = "/run/secrets/restic";
            paths = [ "/srv/bravo" ];
          };
        };
      }
    ];
  };

  topologyEval = import self {
    inherit pkgs;
    modules = [ { nixosConfigurations.svg-test-host = eval; } ];
  };

  elkOutput = topologyEval.config.renderers.elk.output;
  svgOutput = topologyEval.config.renderers.svg.output;
  servicesOverview = topologyEval.config.lib.renderers.svg.services.mkOverview;
in
pkgs.runCommandLocal "svg-render-test" { nativeBuildInputs = with pkgs; [ libxml2 ]; } ''
  echo "=== SVG Render Integration Test ==="

  # --- ELK renderer output ---
  echo "Checking ELK renderer output structure..."
  test -f "${elkOutput}/main.svg" || (echo "FAIL: main.svg missing"; exit 1)
  test -f "${elkOutput}/network.svg" || (echo "FAIL: network.svg missing"; exit 1)

  echo "Validating main.svg is well-formed XML..."
  xmllint --noout "${elkOutput}/main.svg"
  echo "Validating network.svg is well-formed XML..."
  xmllint --noout "${elkOutput}/network.svg"

  echo "Checking main.svg contains expected service names..."
  grep -q "Grafana" "${elkOutput}/main.svg" || (echo "FAIL: 'Grafana' not found in main.svg"; exit 1)
  grep -q "Prometheus" "${elkOutput}/main.svg" || (echo "FAIL: 'Prometheus' not found in main.svg"; exit 1)
  grep -q "grafana.example.com" "${elkOutput}/main.svg" || (echo "FAIL: 'grafana.example.com' not found in main.svg"; exit 1)

  echo "Checking main.svg has SVG root element..."
  grep -q '<svg' "${elkOutput}/main.svg" || (echo "FAIL: no <svg> root element in main.svg"; exit 1)

  # --- Per-node SVG renderer output ---
  echo "Checking per-node SVG output..."
  test -d "${svgOutput}/nodes" || (echo "FAIL: nodes/ directory missing from SVG output"; exit 1)
  test -f "${svgOutput}/nodes/svg-test-host.svg" || (echo "FAIL: svg-test-host.svg missing"; exit 1)

  echo "Validating per-node SVG is well-formed XML..."
  xmllint --noout "${svgOutput}/nodes/svg-test-host.svg"

  echo "Checking per-node SVG contains expected content..."
  grep -q "Grafana" "${svgOutput}/nodes/svg-test-host.svg" || (echo "FAIL: 'Grafana' not found in node SVG"; exit 1)
  grep -q "Prometheus" "${svgOutput}/nodes/svg-test-host.svg" || (echo "FAIL: 'Prometheus' not found in node SVG"; exit 1)
  grep -q "grafana.example.com" "${svgOutput}/nodes/svg-test-host.svg" || (echo "FAIL: 'grafana.example.com' not found in node SVG"; exit 1)

  echo "Checking per-node SVG contains the container's service..."
  grep -q "Jellyfin" "${svgOutput}/nodes/svg-test-host.svg" || (echo "FAIL: 'Jellyfin' not found in node SVG"; exit 1)
  grep -q "Jellyfin" "${elkOutput}/main.svg" || (echo "FAIL: 'Jellyfin' not found in main.svg"; exit 1)
  sed 's/<[^>]*>//g' "${svgOutput}/nodes/svg-test-host.svg" > node.txt
  grep -q "linuxserver/jellyfin" node.txt || (echo "FAIL: container image not found in node SVG"; exit 1)

  echo "Checking services overview lists all services sharing a serviceId..."
  # Text is split into one element per word, so compare the text content only
  sed 's/<[^>]*>//g' "${servicesOverview}" > overview.txt
  grep -q "/mnt/alpha" overview.txt || (echo "FAIL: restic backup 'alpha' not found in services overview"; exit 1)
  grep -q "/mnt/bravo" overview.txt || (echo "FAIL: restic backup 'bravo' not found in services overview"; exit 1)
  grep -q "Jellyfin" overview.txt || (echo "FAIL: container 'Jellyfin' not found in services overview"; exit 1)

  echo "=== All SVG render tests passed ==="
  echo "ok" > $out
''
