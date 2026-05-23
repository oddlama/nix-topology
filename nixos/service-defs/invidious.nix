_: {
  name = "Invidious";
  icon = "services.invidious";
  nixos = {
    path = "services.invidious";
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
    expect = {
      name = "Invidious";
      details.listen = "127.0.0.1:3000";
    };
  };
}
