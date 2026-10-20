{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Komga";
  icon = "services.komga";
  nixos = {
    path = "services.komga";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "0.0.0.0:${toString cfg.settings.server.port}";
        };
      };
  };
  test = {
    config = {
      services.komga = {
        enable = true;
        openFirewall = true;
        settings.server.port = 25600;
      };
    };
    expect = {
      name = "Komga";
      details.listen = "0.0.0.0:25600";
    };
  };
}
