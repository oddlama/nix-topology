{ lib }:
let
  inherit (lib) concatLines map mkIf;
in
{
  name = "Grafana";
  icon = "services.grafana";
  nixos = {
    path = "services.grafana";
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
    expect = {
      name = "Grafana";
      info = "https://grafana.example.com";
      details.listen = "127.0.0.1:3000";
    };
  };
}
