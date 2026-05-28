{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Stirling-PDF";
  icon = "services.stirling-pdf";
  nixos = {
    path = [
      "services"
      "stirling-pdf"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        address = cfg.environment.SERVER_HOST or null;
        port = cfg.environment.SERVER_PORT or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.stirling-pdf = {
        enable = true;
        environment = {
          SERVER_HOST = "0.0.0.0";
          SERVER_PORT = "8080";
        };
      };
    };
    assertions = services: [
      {
        assertion = services.stirling-pdf.name == "Stirling-PDF";
        message = "expected name 'Stirling-PDF', got '${services.stirling-pdf.name}'";
      }
      {
        assertion = services.stirling-pdf.details.listen.text == "0.0.0.0:8080";
        message = "expected listen '0.0.0.0:8080', got '${services.stirling-pdf.details.listen.text}'";
      }
    ];
  };
}
