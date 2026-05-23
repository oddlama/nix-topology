{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Owncast";
  icon = "services.owncast";
  nixos = {
    path = [
      "services"
      "owncast"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      mkIf cfg.openFirewall {
        listen = {
          text = "${cfg.listen}:${toString cfg.port}";
        };
      };
  };
  test = {
    config = {
      services.owncast = {
        enable = true;
        openFirewall = true;
        listen = "0.0.0.0";
        port = 8080;
      };
    };
    assertions = services: [
      {
        assertion = services.owncast.name == "Owncast";
        message = "expected name 'Owncast', got '${services.owncast.name}'";
      }
      {
        assertion = services.owncast.details.listen.text == "0.0.0.0:8080";
        message = "expected listen '0.0.0.0:8080', got '${services.owncast.details.listen.text}'";
      }
    ];
  };
}
