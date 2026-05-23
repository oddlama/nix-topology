{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Mimir";
  icon = "services.mimir";
  nixos = {
    path = [
      "services"
      "mimir"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        address = cfg.configuration.server.http_listen_address or null;
        port = cfg.configuration.server.http_listen_port or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.mimir = {
        enable = true;
        configuration = {
          multitenancy_enabled = false;
          server = {
            http_listen_address = "0.0.0.0";
            http_listen_port = 9009;
          };
        };
      };
    };
    assertions = services: [
      {
        assertion = services.mimir.name == "Mimir";
        message = "expected name 'Mimir', got '${services.mimir.name}'";
      }
      {
        assertion = services.mimir.details.listen.text == "0.0.0.0:9009";
        message = "expected listen '0.0.0.0:9009', got '${services.mimir.details.listen.text}'";
      }
    ];
  };
}
