{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "matrix-appservice-irc";
  icon = "services.not-available";
  nixos = {
    path = "services.matrix-appservice-irc";
    detailsFn =
      { cfg, ... }:
      let
        address = cfg.settings.homeserver.bindHostname or "0.0.0.0";
        port = cfg.port or null;
      in
      {
        listen = mkIf (port != null) { text = "${address}:${toString port}"; };
      };
  };
  test = {
    config = {
      services.matrix-appservice-irc = {
        enable = true;
        port = 8009;
        settings.homeserver.bindHostname = "127.0.0.1";
      };
    };
    expect = {
      name = "matrix-appservice-irc";
      details.listen = "127.0.0.1:8009";
    };
  };
}
