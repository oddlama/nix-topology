{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Scrutiny";
  icon = "services.scrutiny";
  nixos = {
    path = "services.scrutiny";
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.settings.web.listen.host}:${toString cfg.settings.web.listen.port}";
        };
      };
  };
  test = {
    config = {
      services.scrutiny = {
        enable = true;
        openFirewall = true;
        settings.web.listen = {
          host = "0.0.0.0";
          port = 8080;
        };
      };
    };
    expect = {
      name = "Scrutiny";
      details.listen = "0.0.0.0:8080";
    };
  };
}
