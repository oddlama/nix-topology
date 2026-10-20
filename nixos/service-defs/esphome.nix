_: {
  name = "ESPHome";
  icon = "services.esphome";
  nixos = {
    path = "services.esphome";
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
    expect = {
      name = "ESPHome";
      details.listen = "0.0.0.0:6052";
    };
  };
}
