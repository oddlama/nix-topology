{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Stirling-PDF";
  icon = "services.stirling-pdf";
  nixos = {
    path = "services.stirling-pdf";
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
    expect = {
      name = "Stirling-PDF";
      details.listen = "0.0.0.0:8080";
    };
  };
}
