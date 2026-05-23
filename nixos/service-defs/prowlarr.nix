{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Prowlarr";
  icon = "services.prowlarr";
  nixos = {
    path = [
      "services"
      "prowlarr"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:9696";
        };
      };
  };
  test = {
    config = {
      services.prowlarr = {
        enable = true;
        openFirewall = true;
      };
    };
    assertions = services: [
      {
        assertion = services.prowlarr.name == "Prowlarr";
        message = "expected name 'Prowlarr', got '${services.prowlarr.name}'";
      }
      {
        assertion = services.prowlarr.details.listen.text == "0.0.0.0:9696";
        message = "expected listen '0.0.0.0:9696', got '${services.prowlarr.details.listen.text}'";
      }
    ];
  };
}
