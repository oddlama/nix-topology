_: {
  name = "Tabby";
  icon = "services.tabby";
  nixos = {
    path = [
      "services"
      "tabby"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.host}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.tabby = {
        enable = true;
        host = "127.0.0.1";
        port = 8080;
      };
    };
    assertions = services: [
      {
        assertion = services.tabby.name == "Tabby";
        message = "expected name 'Tabby', got '${services.tabby.name}'";
      }
      {
        assertion = services.tabby.details.listen.text == "127.0.0.1:8080";
        message = "expected listen '127.0.0.1:8080', got '${services.tabby.details.listen.text}'";
      }
    ];
  };
}
