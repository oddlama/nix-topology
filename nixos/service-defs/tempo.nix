{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Tempo";
  icon = "services.tempo";
  nixos = {
    path = [
      "services"
      "tempo"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        address = cfg.settings.server.http_listen_address or null;
        port = cfg.settings.server.http_listen_port or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${port}";
        };
      };
  };
  test = {
    config = {
      services.tempo = {
        enable = true;
        settings.server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = "3200";
        };
      };
    };
    assertions = services: [
      {
        assertion = services.tempo.name == "Tempo";
        message = "expected name 'Tempo', got '${services.tempo.name}'";
      }
      {
        assertion = services.tempo.details.listen.text == "0.0.0.0:3200";
        message = "expected listen '0.0.0.0:3200', got '${services.tempo.details.listen.text}'";
      }
    ];
  };
}
