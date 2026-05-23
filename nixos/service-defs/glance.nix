{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Glance";
  icon = "services.glance";
  nixos = {
    path = [
      "services"
      "glance"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.settings.server.host}:${toString cfg.settings.server.port}";
        };
      };
  };
  test = {
    config = {
      services.glance = {
        enable = true;
        openFirewall = true;
        settings.server = {
          host = "0.0.0.0";
          port = 8080;
        };
      };
    };
    assertions = services: [
      {
        assertion = services.glance.name == "Glance";
        message = "expected name 'Glance', got '${services.glance.name}'";
      }
      {
        assertion = services.glance.details.listen.text == "0.0.0.0:8080";
        message = "expected listen '0.0.0.0:8080', got '${services.glance.details.listen.text}'";
      }
    ];
  };
}
