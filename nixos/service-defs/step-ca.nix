{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "step-ca";
  icon = "services.step-ca";
  nixos = {
    path = "services.step-ca";
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
    expect = {
      name = "step-ca";
      details.listen = "0.0.0.0:8443";
    };
  };
}
