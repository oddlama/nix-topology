{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Immich";
  icon = "services.immich";
  nixos = {
    path = [
      "services"
      "immich"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.host}:${toString cfg.port}";
        };
      };
  };
  test = {
    config = {
      services.immich = {
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        port = 2283;
      };
    };
    assertions = services: [
      {
        assertion = services.immich.name == "Immich";
        message = "expected name 'Immich', got '${services.immich.name}'";
      }
      {
        assertion = services.immich.details.listen.text == "0.0.0.0:2283";
        message = "expected listen '0.0.0.0:2283', got '${services.immich.details.listen.text}'";
      }
    ];
  };
}
