{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Anki";
  icon = "services.anki";
  nixos = {
    path = [
      "services"
      "anki-sync-server"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.address}:${toString cfg.port}";
        };
      };
  };
  test = {
    config = {
      services.anki-sync-server = {
        enable = true;
        openFirewall = true;
        address = "0.0.0.0";
        port = 27701;
      };
    };
    assertions = services: [
      {
        assertion = services.anki.name == "Anki";
        message = "expected name 'Anki', got '${services.anki.name}'";
      }
      {
        assertion = services.anki.details.listen.text == "0.0.0.0:27701";
        message = "expected listen '0.0.0.0:27701', got '${services.anki.details.listen.text}'";
      }
    ];
  };
}
