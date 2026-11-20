_: {
  name = "Cook CLI";
  icon = "services.cook-cli";
  nixos = {
    path = "services.cook-cli";
    # The module always starts the server with `--host`, which listens on every interface
    detailsFn = { cfg, ... }: {
      listen = {
        text = "0.0.0.0:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.cook-cli = {
        enable = true;
        port = 9080;
      };
    };
    expect = {
      name = "Cook CLI";
      details.listen = "0.0.0.0:9080";
    };
  };
}
