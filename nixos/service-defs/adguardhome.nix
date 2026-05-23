{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "AdGuard Home";
  icon = "services.adguardhome";
  nixos = {
    path = [
      "services"
      "adguardhome"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        address = cfg.host or null;
        port = cfg.port or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.adguardhome = {
        enable = true;
        host = "0.0.0.0";
        port = 3000;
      };
    };
    assertions = services: [
      {
        assertion = services.adguardhome.name == "AdGuard Home";
        message = "expected name 'AdGuard Home', got '${services.adguardhome.name}'";
      }
      {
        assertion = services.adguardhome.details.listen.text == "0.0.0.0:3000";
        message = "expected listen '0.0.0.0:3000', got '${services.adguardhome.details.listen.text}'";
      }
    ];
  };
}
