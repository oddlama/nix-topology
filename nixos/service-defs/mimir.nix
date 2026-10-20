{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Mimir";
  icon = "services.mimir";
  nixos = {
    path = "services.mimir";
    detailsFn =
      cfg:
      let
        address = cfg.configuration.server.http_listen_address or null;
        port = cfg.configuration.server.http_listen_port or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.mimir = {
        enable = true;
        configuration = {
          multitenancy_enabled = false;
          server = {
            http_listen_address = "0.0.0.0";
            http_listen_port = 9009;
          };
        };
      };
    };
    expect = {
      name = "Mimir";
      details.listen = "0.0.0.0:9009";
    };
  };
}
