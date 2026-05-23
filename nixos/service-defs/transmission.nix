{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Transmission";
  icon = "services.transmission";
  nixos = {
    path = "services.transmission";
    detailsFn =
      cfg:
      let
        address = cfg.settings.rpc-bind-address or null;
        port = cfg.settings.rpc-port or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.transmission = {
        enable = true;
        settings = {
          rpc-bind-address = "0.0.0.0";
          rpc-port = 9091;
        };
      };
    };
    expect = {
      name = "Transmission";
      details.listen = "0.0.0.0:9091";
    };
  };
}
