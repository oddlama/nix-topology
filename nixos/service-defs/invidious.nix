_: {
  name = "Invidious";
  icon = "services.invidious";
  nixos = {
    path = [
      "services"
      "invidious"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.address}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.invidious = {
        enable = true;
        address = "127.0.0.1";
        port = 3000;
      };
    };
    assertions = services: [
      {
        assertion = services.invidious.name == "Invidious";
        message = "expected name 'Invidious', got '${services.invidious.name}'";
      }
      {
        assertion = services.invidious.details.listen.text == "127.0.0.1:3000";
        message = "expected listen '127.0.0.1:3000', got '${services.invidious.details.listen.text}'";
      }
    ];
  };
}
