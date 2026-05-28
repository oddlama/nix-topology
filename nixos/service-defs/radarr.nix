{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Radarr";
  icon = "services.radarr";
  nixos = {
    path = [
      "services"
      "radarr"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:7878";
        };
      };
  };
  test = {
    config = {
      services.radarr = {
        enable = true;
        openFirewall = true;
      };
    };
    assertions = services: [
      {
        assertion = services.radarr.name == "Radarr";
        message = "expected name 'Radarr', got '${services.radarr.name}'";
      }
      {
        assertion = services.radarr.details.listen.text == "0.0.0.0:7878";
        message = "expected listen '0.0.0.0:7878', got '${services.radarr.details.listen.text}'";
      }
    ];
  };
}
