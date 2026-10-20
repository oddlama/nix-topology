{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Open Webui";
  icon = "services.open-webui";
  nixos = {
    path = "services.open-webui";
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
      services.open-webui = {
        enable = true;
        openFirewall = true;
        host = "0.0.0.0";
        port = 8080;
      };
    };
    expect = {
      name = "Open Webui";
      details.listen = "0.0.0.0:8080";
    };
  };
}
