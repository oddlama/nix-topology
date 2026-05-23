{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Code Server";
  icon = "services.code-server";
  nixos = {
    path = "services.code-server";
    detailsFn =
      cfg:
      let
        host = cfg.host or null;
        port = cfg.port or null;
      in
      mkIf (host != null && port != null) {
        listen = {
          text = "${host}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.code-server = {
        enable = true;
        host = "127.0.0.1";
        port = 4444;
      };
    };
    expect = {
      name = "Code Server";
      details.listen = "127.0.0.1:4444";
    };
  };
}
