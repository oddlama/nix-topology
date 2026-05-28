{ lib }:
let
  inherit (lib) mkIf;
in
{
  name = "Firefox Syncserver";
  icon = "services.firefox-syncserver";
  nixos = {
    path = [
      "services"
      "firefox-syncserver"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: mkIf (cfg.singleNode.enable or false) cfg.singleNode.url;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.settings.host or "127.0.0.1"}:${toString cfg.settings.port}";
      };
    };
  };
  test = {
    config = {
      services.firefox-syncserver = {
        enable = true;
        singleNode = {
          enable = true;
          url = "https://sync.example.com";
          hostname = "localhost";
        };
        secrets.master-password = "/dev/null";
        settings = {
          host = "0.0.0.0";
          port = 5000;
          database_url = "postgresql:///syncstorage";
        };
      };
    };
    assertions = services: [
      {
        assertion = services.firefox-syncserver.name == "Firefox Syncserver";
        message = "expected name 'Firefox Syncserver', got '${services.firefox-syncserver.name}'";
      }
      {
        assertion = services.firefox-syncserver.info == "https://sync.example.com";
        message = "expected info 'https://sync.example.com', got '${services.firefox-syncserver.info}'";
      }
      {
        assertion = services.firefox-syncserver.details.listen.text == "0.0.0.0:5000";
        message = "expected listen '0.0.0.0:5000', got '${services.firefox-syncserver.details.listen.text}'";
      }
    ];
  };
}
