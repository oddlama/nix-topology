{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Deluge";
  icon = "services.deluge";
  nixos = {
    path = [
      "services"
      "deluge"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        daemonPort = cfg.config.daemon_port or 58846;
        webPort = cfg.web.port or null;
      in
      {
        listen = {
          text = "0.0.0.0:${toString daemonPort}";
        };
        webUI = mkIf (cfg.web.enable && webPort != null) { text = "0.0.0.0:${toString webPort}"; };
      };
  };
  test = {
    config = {
      services.deluge = {
        enable = true;
        config.daemon_port = 58846;
        web = {
          enable = true;
          port = 8112;
        };
      };
    };
    assertions = services: [
      {
        assertion = services.deluge.name == "Deluge";
        message = "expected name 'Deluge', got '${services.deluge.name}'";
      }
      {
        assertion = services.deluge.details.listen.text == "0.0.0.0:58846";
        message = "expected listen '0.0.0.0:58846', got '${services.deluge.details.listen.text}'";
      }
      {
        assertion = services.deluge.details.webUI.text == "0.0.0.0:8112";
        message = "expected webUI '0.0.0.0:8112', got '${services.deluge.details.webUI.text}'";
      }
    ];
  };
}
