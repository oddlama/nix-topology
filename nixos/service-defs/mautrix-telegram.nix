{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "mautrix-telegram";
  icon = "services.mautrix-telegram";
  nixos = {
    path = [
      "services"
      "mautrix-telegram"
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
    assertions = services: [
      {
        assertion = services.mautrix-telegram.name == "mautrix-telegram";
        message = "expected name 'mautrix-telegram', got '${services.mautrix-telegram.name}'";
      }
      {
        assertion = services.mautrix-telegram.details.listen.text == "127.0.0.1:29317";
        message = "expected listen '127.0.0.1:29317', got '${services.mautrix-telegram.details.listen.text}'";
      }
    ];
  };
}
