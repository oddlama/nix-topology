{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "mautrix-whatsapp";
  icon = "services.mautrix-whatsapp";
  nixos = {
    path = [
      "services"
      "mautrix-whatsapp"
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
      services.mautrix-whatsapp = {
        enable = true;
        settings.appservice = {
          hostname = "127.0.0.1";
          port = 29318;
        };
      };
    };
    assertions = services: [
      {
        assertion = services.mautrix-whatsapp.name == "mautrix-whatsapp";
        message = "expected name 'mautrix-whatsapp', got '${services.mautrix-whatsapp.name}'";
      }
      {
        assertion = services.mautrix-whatsapp.details.listen.text == "127.0.0.1:29318";
        message = "expected listen '127.0.0.1:29318', got '${services.mautrix-whatsapp.details.listen.text}'";
      }
    ];
  };
}
