_: {
  name = "ESPHome";
  icon = "services.esphome";
  nixos = {
    path = [
      "services"
      "esphome"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text =
          if cfg.enableUnixSocket or false then
            "/run/esphome/esphome.sock"
          else
            "${cfg.address}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.esphome = {
        enable = true;
        address = "0.0.0.0";
        port = 6052;
      };
    };
    assertions = services: [
      {
        assertion = services.esphome.name == "ESPHome";
        message = "expected name 'ESPHome', got '${services.esphome.name}'";
      }
      {
        assertion = services.esphome.details.listen.text == "0.0.0.0:6052";
        message = "expected listen '0.0.0.0:6052', got '${services.esphome.details.listen.text}'";
      }
    ];
  };
}
