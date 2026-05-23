{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Immich";
  icon = "services.immich";
  nixos = {
    path = "services.immich";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.host}:${toString cfg.port}";
        };
      };
  };
  test = {
    config = {
      services.immich = {
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        port = 2283;
      };
    };
    expect = {
      name = "Immich";
      details.listen = "0.0.0.0:2283";
    };
  };
}
