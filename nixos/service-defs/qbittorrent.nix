{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "qBittorrent";
  icon = "services.qbittorrent";
  nixos = {
    path = "services.qbittorrent";
    detailsFn =
      { cfg, ... }:
      let
        address = cfg.serverConfig.Preferences.WebUI.Address or null;
        port = cfg.webuiPort;
      in
      {
        listen = mkIf (address != null && port != null) { text = "${address}:${toString port}"; };
      };
  };
  test = {
    config = {
      services.qbittorrent = {
        enable = true;
        webuiPort = 8080;
        serverConfig.Preferences.WebUI.Address = "127.0.0.1";
      };
    };
    expect = {
      name = "qBittorrent";
      details.listen = "127.0.0.1:8080";
    };
  };
}
