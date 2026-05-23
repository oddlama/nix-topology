{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Glance";
  icon = "services.glance";
  nixos = {
    path = "services.glance";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.settings.server.host}:${toString cfg.settings.server.port}";
        };
      };
  };
  test = {
    config = {
      services.glance = {
        enable = true;
        openFirewall = true;
        settings.server = {
          host = "0.0.0.0";
          port = 8080;
        };
      };
    };
    expect = {
      name = "Glance";
      details.listen = "0.0.0.0:8080";
    };
  };
}
