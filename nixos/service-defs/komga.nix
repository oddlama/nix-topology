{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Komga";
  icon = "services.komga";
  nixos = {
    path = [
      "services"
      "komga"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:${toString cfg.settings.server.port}";
        };
      };
  };
  test = {
    config = {
      services.komga = {
        enable = true;
        openFirewall = true;
        settings.server.port = 25600;
      };
    };
    assertions = services: [
      {
        assertion = services.komga.name == "Komga";
        message = "expected name 'Komga', got '${services.komga.name}'";
      }
      {
        assertion = services.komga.details.listen.text == "0.0.0.0:25600";
        message = "expected listen '0.0.0.0:25600', got '${services.komga.details.listen.text}'";
      }
    ];
  };
}
