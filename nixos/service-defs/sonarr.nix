{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Sonarr";
  icon = "services.sonarr";
  nixos = {
    path = [
      "services"
      "sonarr"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:8989";
        };
      };
  };
  test = {
    config = {
      services.sonarr = {
        enable = true;
        openFirewall = true;
      };
    };
    assertions = services: [
      {
        assertion = services.sonarr.name == "Sonarr";
        message = "expected name 'Sonarr', got '${services.sonarr.name}'";
      }
      {
        assertion = services.sonarr.details.listen.text == "0.0.0.0:8989";
        message = "expected listen '0.0.0.0:8989', got '${services.sonarr.details.listen.text}'";
      }
    ];
  };
}
