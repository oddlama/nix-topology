{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Seerr";
  icon = "services.seerr";
  nixos = {
    path = [
      "services"
      "seerr"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf (cfg.openFirewall or false) {
        listen = {
          text = "0.0.0.0:${toString cfg.port}";
        };
      };
  };
  test = {
    config = {
      services.seerr = {
        enable = true;
        openFirewall = true;
        port = 5055;
      };
    };
    assertions = services: [
      {
        assertion = services.seerr.name == "Seerr";
        message = "expected name 'Seerr', got '${services.seerr.name}'";
      }
      {
        assertion = services.seerr.details.listen.text == "0.0.0.0:5055";
        message = "expected listen '0.0.0.0:5055', got '${services.seerr.details.listen.text}'";
      }
    ];
  };
}
