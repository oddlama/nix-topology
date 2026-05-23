{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Loki";
  icon = "services.loki";
  nixos = {
    path = "services.loki";
    detailsFn =
      cfg:
      let
        addr = cfg.configuration.server.http_listen_address or null;
        port = cfg.configuration.server.http_listen_port or null;
      in
      mkIf (addr != null && port != null) {
        listen = {
          text = "${addr}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.loki = {
        enable = true;
        configuration = {
          auth_enabled = false;
          server = {
            http_listen_address = "127.0.0.1";
            http_listen_port = 3100;
          };
        };
      };
    };
    expect = {
      name = "Loki";
      details.listen = "127.0.0.1:3100";
    };
  };
}
