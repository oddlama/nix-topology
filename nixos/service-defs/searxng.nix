{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "SearXNG";
  icon = "services.searxng";
  nixos = {
    path = [
      "services"
      "searx"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        address = cfg.settings.server.bind_address or null;
        port = cfg.settings.server.port or null;
      in
      mkIf (address != null && port != null) {
        listen = {
          text = "${address}:${toString port}";
        };
      };
  };
  test = {
    config = {
      services.searx = {
        enable = true;
        settings.server = {
          bind_address = "127.0.0.1";
          port = 8888;
          secret_key = "test-secret";
        };
      };
    };
    assertions = services: [
      {
        assertion = services.searxng.name == "SearXNG";
        message = "expected name 'SearXNG', got '${services.searxng.name}'";
      }
      {
        assertion = services.searxng.details.listen.text == "127.0.0.1:8888";
        message = "expected listen '127.0.0.1:8888', got '${services.searxng.details.listen.text}'";
      }
    ];
  };
}
