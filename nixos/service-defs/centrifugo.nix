{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Centrifugo";
  icon = "services.centrifugo";
  nixos = {
    path = "services.centrifugo";
    detailsFn =
      { cfg, ... }:
      let
        address = cfg.settings.http_server.address or null;
        port = cfg.settings.http_server.port or null;
      in
      {
        listen = mkIf (address != null && port != null) { text = "${address}:${toString port}"; };
      };
  };
  test = {
    config = {
      services.centrifugo = {
        enable = true;
        settings.http_server = {
          address = "127.0.0.1";
          port = 8000;
        };
      };
    };
    expect = {
      name = "Centrifugo";
      details.listen = "127.0.0.1:8000";
    };
  };
}
