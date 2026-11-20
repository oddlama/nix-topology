_: {
  name = "OpenCloud";
  icon = "services.opencloud";
  nixos = {
    path = "services.opencloud";
    infoFn = { cfg, ... }: cfg.url;
    detailsFn = { cfg, ... }: {
      listen = {
        text = "${cfg.address}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.opencloud = {
        enable = true;
        url = "https://cloud.example.com";
        address = "127.0.0.1";
        port = 9200;
      };
    };
    expect = {
      name = "OpenCloud";
      info = "https://cloud.example.com";
      details.listen = "127.0.0.1:9200";
    };
  };
}
