{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Deluge";
  icon = "services.deluge";
  nixos = {
    path = "services.deluge";
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
    expect = {
      name = "Deluge";
      details.listen = "0.0.0.0:58846";
      details.webUI = "0.0.0.0:8112";
    };
  };
}
