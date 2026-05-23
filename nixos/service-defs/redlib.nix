{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Redlib";
  icon = "services.redlib";
  nixos = {
    path = [
      "services"
      "redlib"
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
      services.redlib = {
        enable = true;
        openFirewall = true;
        address = "0.0.0.0";
        port = 8080;
      };
    };
    assertions = services: [
      {
        assertion = services.redlib.name == "Redlib";
        message = "expected name 'Redlib', got '${services.redlib.name}'";
      }
      {
        assertion = services.redlib.details.listen.text == "0.0.0.0:8080";
        message = "expected listen '0.0.0.0:8080', got '${services.redlib.details.listen.text}'";
      }
    ];
  };
}
