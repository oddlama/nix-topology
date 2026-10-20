_: {
  name = "Libretranslate";
  icon = "services.libretranslate";
  nixos = {
    path = "services.libretranslate";
    detailsFn = cfg: {
      listen = {
        text = "${cfg.host}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.libretranslate = {
        enable = true;
        host = "0.0.0.0";
        port = 5000;
      };
    };
    expect = {
      name = "Libretranslate";
      details.listen = "0.0.0.0:5000";
    };
  };
}
