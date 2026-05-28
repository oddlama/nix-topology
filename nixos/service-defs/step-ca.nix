{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "step-ca";
  icon = "services.step-ca";
  nixos = {
    path = [
      "services"
      "step-ca"
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
      services.step-ca = {
        enable = true;
        openFirewall = true;
        address = "0.0.0.0";
        port = 8443;
        intermediatePasswordFile = "/dev/null";
        settings = {
          root = "/dev/null";
          crt = "/dev/null";
          key = "/dev/null";
          dnsNames = [ "ca.example.com" ];
        };
      };
    };
    assertions = services: [
      {
        assertion = services.step-ca.name == "step-ca";
        message = "expected name 'step-ca', got '${services.step-ca.name}'";
      }
      {
        assertion = services.step-ca.details.listen.text == "0.0.0.0:8443";
        message = "expected listen '0.0.0.0:8443', got '${services.step-ca.details.listen.text}'";
      }
    ];
  };
}
