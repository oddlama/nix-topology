{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "mautrix-telegram";
  icon = "services.mautrix-telegram";
  nixos = {
    path = "services.mautrix-telegram";
    detailsFn =
      cfg:
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
      services.mautrix-telegram = {
        enable = true;
        settings = {
          homeserver.address = "http://localhost:8008";
          appservice = {
            hostname = "127.0.0.1";
            port = 29317;
          };
        };
      };
    };
    expect = {
      name = "mautrix-telegram";
      details.listen = "127.0.0.1:29317";
    };
  };
}
