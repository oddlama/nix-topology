{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Code Server";
  icon = "services.code-server";
  nixos = {
    path = [
      "services"
      "code-server"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.code-server.name == "Code Server";
        message = "expected name 'Code Server', got '${services.code-server.name}'";
      }
      {
        assertion = services.code-server.details.listen.text == "127.0.0.1:4444";
        message = "expected listen '127.0.0.1:4444', got '${services.code-server.details.listen.text}'";
      }
    ];
  };
}
