_: {
  name = "Headscale";
  icon = "services.headscale";
  nixos = {
    path = "services.headscale";
    infoFn = cfg: cfg.settings.server_url;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.address}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.headscale = {
        enable = true;
        address = "0.0.0.0";
        port = 8080;
        settings.server_url = "https://headscale.example.com";
      };
    };
    expect = {
      name = "Headscale";
      info = "https://headscale.example.com";
      details.listen = "0.0.0.0:8080";
    };
  };
}
