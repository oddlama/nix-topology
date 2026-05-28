{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "mautrix-signal";
  icon = "services.mautrix-signal";
  nixos = {
    path = [
      "services"
      "mautrix-signal"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.mautrix-signal.name == "mautrix-signal";
        message = "expected name 'mautrix-signal', got '${services.mautrix-signal.name}'";
      }
      {
        assertion = services.mautrix-signal.details.listen.text == "127.0.0.1:29328";
        message = "expected listen '127.0.0.1:29328', got '${services.mautrix-signal.details.listen.text}'";
      }
    ];
  };
}
