{ lib }:
let
  inherit (lib) concatLines map mkIf;
in
{
  name = "Grafana";
  icon = "services.grafana";
  nixos = {
    path = [
      "services"
      "grafana"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: cfg.settings.server.root_url;
    detailsFn =
      cfg:
      let
        addr = cfg.settings.server.http_addr or null;
        port = cfg.settings.server.http_port or null;
        plugins = cfg.declarativePlugins or null;
      in
      {
        listen = mkIf (addr != null && port != null) { text = "${addr}:${toString port}"; };
        plugins = mkIf (plugins != null) { text = concatLines (map (p: p.name) plugins); };
      };
  };
  test = {
    config = {
      services.grafana = {
        enable = true;
        settings.server = {
          root_url = "https://grafana.example.com";
          http_addr = "127.0.0.1";
          http_port = 3000;
        };
      };
    };
    assertions = services: [
      {
        assertion = services.grafana.name == "Grafana";
        message = "expected name 'Grafana', got '${services.grafana.name}'";
      }
      {
        assertion = services.grafana.info == "https://grafana.example.com";
        message = "expected info 'https://grafana.example.com', got '${services.grafana.info}'";
      }
      {
        assertion = services.grafana.details.listen.text == "127.0.0.1:3000";
        message = "expected listen '127.0.0.1:3000', got '${services.grafana.details.listen.text}'";
      }
    ];
  };
}
