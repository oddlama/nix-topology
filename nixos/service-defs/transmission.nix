{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Transmission";
  icon = "services.transmission";
  nixos = {
    path = [
      "services"
      "transmission"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        address = cfg.settings.rpc-bind-address or null;
        port = cfg.settings.rpc-port or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.transmission = {
        enable = true;
        settings = {
          rpc-bind-address = "0.0.0.0";
          rpc-port = 9091;
        };
      };
    };
    assertions = services: [
      {
        assertion = services.transmission.name == "Transmission";
        message = "expected name 'Transmission', got '${services.transmission.name}'";
      }
      {
        assertion = services.transmission.details.listen.text == "0.0.0.0:9091";
        message = "expected listen '0.0.0.0:9091', got '${services.transmission.details.listen.text}'";
      }
    ];
  };
}
