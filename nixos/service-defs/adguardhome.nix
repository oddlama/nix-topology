{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "AdGuard Home";
  icon = "services.adguardhome";
  nixos = {
    path = "services.adguardhome";
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
    expect = {
      name = "AdGuard Home";
      details.listen = "0.0.0.0:3000";
    };
  };
}
