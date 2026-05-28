{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Lidarr";
  icon = "services.lidarr";
  nixos = {
    path = [
      "services"
      "lidarr"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:8686";
        };
      };
  };
  test = {
    config = {
      services.lidarr = {
        enable = true;
        openFirewall = true;
      };
    };
    assertions = services: [
      {
        assertion = services.lidarr.name == "Lidarr";
        message = "expected name 'Lidarr', got '${services.lidarr.name}'";
      }
      {
        assertion = services.lidarr.details.listen.text == "0.0.0.0:8686";
        message = "expected listen '0.0.0.0:8686', got '${services.lidarr.details.listen.text}'";
      }
    ];
  };
}
