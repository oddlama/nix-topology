_: {
  name = "Forgejo";
  icon = "services.forgejo";
  nixos = {
    path = "services.forgejo";
    nameFn =
      cfg:
      if cfg.settings ? DEFAULT.APP_NAME then "Forgejo (${cfg.settings.DEFAULT.APP_NAME})" else "Forgejo";
    infoFn = cfg: cfg.settings.server.ROOT_URL;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.settings.server.HTTP_ADDR}:${toString cfg.settings.server.HTTP_PORT}";
      };
    };
  };
  test = {
    config = {
      services.forgejo = {
        enable = true;
        settings = {
          DEFAULT.APP_NAME = "My Forge";
          server = {
            ROOT_URL = "https://forgejo.example.com";
            HTTP_ADDR = "127.0.0.1";
            HTTP_PORT = 3000;
          };
        };
      };
    };
    expect = {
      name = "Forgejo (My Forge)";
      info = "https://forgejo.example.com";
      details.listen = "127.0.0.1:3000";
    };
  };
}
