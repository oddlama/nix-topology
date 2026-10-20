{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "mautrix-whatsapp";
  icon = "services.mautrix-whatsapp";
  nixos = {
    path = "services.mautrix-whatsapp";
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
    expect = {
      name = "mautrix-whatsapp";
      details.listen = "127.0.0.1:29318";
    };
  };
}
