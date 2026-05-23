{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Redlib";
  icon = "services.redlib";
  nixos = {
    path = "services.redlib";
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
    expect = {
      name = "Redlib";
      details.listen = "0.0.0.0:8080";
    };
  };
}
