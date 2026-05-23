{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Open Webui";
  icon = "services.open-webui";
  nixos = {
    path = [
      "services"
      "open-webui"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.open-webui.name == "Open Webui";
        message = "expected name 'Open Webui', got '${services.open-webui.name}'";
      }
      {
        assertion = services.open-webui.details.listen.text == "0.0.0.0:8080";
        message = "expected listen '0.0.0.0:8080', got '${services.open-webui.details.listen.text}'";
      }
    ];
  };
}
