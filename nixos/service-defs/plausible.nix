{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Plausible";
  icon = "services.plausible";
  nixos = {
    path = [
      "services"
      "plausible"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        listenAddress = cfg.server.listenAddress or null;
        port = cfg.server.port or null;
      in
      mkIf (listenAddress != null && port != null) {
        listen = {
          text = "${listenAddress}:${toString port}";
        };
      };
    infoFn = cfg: cfg.server.baseUrl;
  };
  test = {
    config = {
      services.plausible = {
        enable = true;
        server = {
          listenAddress = "0.0.0.0";
          port = 8000;
          baseUrl = "https://plausible.example.com";
          secretKeybaseFile = "/dev/null";
        };
      };
    };
    assertions = services: [
      {
        assertion = services.plausible.name == "Plausible";
        message = "expected name 'Plausible', got '${services.plausible.name}'";
      }
      {
        assertion = services.plausible.info == "https://plausible.example.com";
        message = "expected info 'https://plausible.example.com', got '${services.plausible.info}'";
      }
      {
        assertion = services.plausible.details.listen.text == "0.0.0.0:8000";
        message = "expected listen '0.0.0.0:8000', got '${services.plausible.details.listen.text}'";
      }
    ];
  };
}
