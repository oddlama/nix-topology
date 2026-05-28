_: {
  name = "Zipline";
  icon = "services.zipline";
  nixos = {
    path = [
      "services"
      "zipline"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.settings.CORE_HOSTNAME}:${toString cfg.settings.CORE_PORT}";
      };
    };
  };
  test = {
    config = {
      services.zipline = {
        enable = true;
        settings = {
          CORE_HOSTNAME = "0.0.0.0";
          CORE_PORT = 3000;
        };
      };
    };
    assertions = services: [
      {
        assertion = services.zipline.name == "Zipline";
        message = "expected name 'Zipline', got '${services.zipline.name}'";
      }
      {
        assertion = services.zipline.details.listen.text == "0.0.0.0:3000";
        message = "expected listen '0.0.0.0:3000', got '${services.zipline.details.listen.text}'";
      }
    ];
  };
}
