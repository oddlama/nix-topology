{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Tempo";
  icon = "services.tempo";
  nixos = {
    path = "services.tempo";
    detailsFn =
      cfg:
      let
        address = cfg.settings.server.http_listen_address or null;
        port = cfg.settings.server.http_listen_port or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.tempo = {
        enable = true;
        settings.server = {
          http_listen_address = "0.0.0.0";
          http_listen_port = "3200";
        };
      };
    };
    expect = {
      name = "Tempo";
      details.listen = "0.0.0.0:3200";
    };
  };
}
