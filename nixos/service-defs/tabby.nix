_: {
  name = "Tabby";
  icon = "services.tabby";
  nixos = {
    path = "services.tabby";
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
    expect = {
      name = "Tabby";
      details.listen = "127.0.0.1:8080";
    };
  };
}
