_: {
  name = "Prometheus";
  icon = "services.prometheus";
  nixos = {
    path = "services.prometheus";
    detailsFn = cfg: {
      listen = {
        text = "${cfg.listenAddress}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.prometheus = {
        enable = true;
        listenAddress = "0.0.0.0";
        port = 9090;
      };
    };
    expect = {
      name = "Prometheus";
      details.listen = "0.0.0.0:9090";
    };
  };
}
