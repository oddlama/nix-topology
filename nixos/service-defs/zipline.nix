_: {
  name = "Zipline";
  icon = "services.zipline";
  nixos = {
    path = "services.zipline";
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
    expect = {
      name = "Zipline";
      details.listen = "0.0.0.0:3000";
    };
  };
}
