_: {
  name = "Static Web Server";
  icon = "devices.nixos";
  nixos = {
    path = [
      "services"
      "static-web-server"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = toString cfg.listen;
      };
      root = {
        text = toString cfg.root;
      };
    };
  };
  test = {
    config = {
      services.static-web-server = {
        enable = true;
        listen = "0.0.0.0:8787";
        root = "/var/www";
      };
    };
    assertions = services: [
      {
        assertion = services.static-web-server.name == "Static Web Server";
        message = "expected name 'Static Web Server', got '${services.static-web-server.name}'";
      }
      {
        assertion = services.static-web-server.details.listen.text == "0.0.0.0:8787";
        message = "expected listen '0.0.0.0:8787', got '${services.static-web-server.details.listen.text}'";
      }
      {
        assertion = services.static-web-server.details.root.text == "/var/www";
        message = "expected root '/var/www', got '${services.static-web-server.details.root.text}'";
      }
    ];
  };
}
