{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "mautrix-discord";
  icon = "services.mautrix-discord";
  nixos = {
    path = "services.mautrix-discord";
    detailsFn =
      { cfg, ... }:
      let
        address = cfg.settings.appservice.hostname or null;
        port = cfg.settings.appservice.port or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.mautrix-discord = {
        enable = true;
        settings.appservice = {
          hostname = "127.0.0.1";
          port = 29334;
        };
      };
    };
    expect = {
      name = "mautrix-discord";
      details.listen = "127.0.0.1:29334";
    };
  };
}
