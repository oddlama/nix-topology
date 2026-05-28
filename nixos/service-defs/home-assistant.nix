{ lib }:
let
  inherit (lib) flip map;
in
{
  name = "Home Assistant";
  icon = "services.home-assistant";
  nixos = {
    path = [
      "services"
      "home-assistant"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = toString (
          flip map cfg.config.http.server_host (addr: "${addr}:${toString cfg.config.http.server_port}")
        );
      };
    };
  };
  test = {
    config = {
      services.home-assistant = {
        enable = true;
        config.http = {
          server_host = [
            "0.0.0.0"
            "::0"
          ];
          server_port = 8123;
        };
      };
    };
    assertions = services: [
      {
        assertion = services.home-assistant.name == "Home Assistant";
        message = "expected name 'Home Assistant', got '${services.home-assistant.name}'";
      }
      {
        assertion = services.home-assistant.details.listen.text == "0.0.0.0:8123 ::0:8123";
        message = "expected listen '0.0.0.0:8123 ::0:8123', got '${services.home-assistant.details.listen.text}'";
      }
    ];
  };
}
