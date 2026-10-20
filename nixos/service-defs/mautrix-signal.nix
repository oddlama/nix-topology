{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "mautrix-signal";
  icon = "services.mautrix-signal";
  nixos = {
    path = "services.mautrix-signal";
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
      services.mautrix-signal = {
        enable = true;
        settings.appservice = {
          hostname = "127.0.0.1";
          port = 29328;
        };
      };
    };
    expect = {
      name = "mautrix-signal";
      details.listen = "127.0.0.1:29328";
    };
  };
}
