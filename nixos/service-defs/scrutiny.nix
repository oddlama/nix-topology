{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Scrutiny";
  icon = "services.scrutiny";
  nixos = {
    path = [
      "services"
      "scrutiny"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.settings.web.listen.host}:${toString cfg.settings.web.listen.port}";
        };
      };
  };
  test = {
    config = {
      services.scrutiny = {
        enable = true;
        openFirewall = true;
        settings.web.listen = {
          host = "0.0.0.0";
          port = 8080;
        };
      };
    };
    assertions = services: [
      {
        assertion = services.scrutiny.name == "Scrutiny";
        message = "expected name 'Scrutiny', got '${services.scrutiny.name}'";
      }
      {
        assertion = services.scrutiny.details.listen.text == "0.0.0.0:8080";
        message = "expected listen '0.0.0.0:8080', got '${services.scrutiny.details.listen.text}'";
      }
    ];
  };
}
