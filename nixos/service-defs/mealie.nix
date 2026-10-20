_: {
  name = "Mealie";
  icon = "services.mealie";
  nixos = {
    path = "services.mealie";
    detailsFn = cfg: {
      listen = {
        text = "${cfg.listenAddress}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.mealie = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9000;
      };
    };
    expect = {
      name = "Mealie";
      details.listen = "127.0.0.1:9000";
    };
  };
}
