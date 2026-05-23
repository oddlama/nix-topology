{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Radicale";
  icon = "services.radicale";
  nixos = {
    path = [
      "services"
      "radicale"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf (cfg.settings ? server.hosts) {
        listen = {
          text = toString cfg.settings.server.hosts;
        };
      };
  };
  test = {
    config = {
      services.radicale = {
        enable = true;
        settings.server.hosts = [ "0.0.0.0:5232" ];
      };
    };
    assertions = services: [
      {
        assertion = services.radicale.name == "Radicale";
        message = "expected name 'Radicale', got '${services.radicale.name}'";
      }
      {
        assertion = services.radicale.details.listen.text == "0.0.0.0:5232";
        message = "expected listen '0.0.0.0:5232', got '${services.radicale.details.listen.text}'";
      }
    ];
  };
}
