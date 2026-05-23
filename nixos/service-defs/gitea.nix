_: {
  name = "gitea";
  icon = "services.gitea";
  nixos = {
    path = "services.gitea";
    nameFn =
      cfg:
      if cfg.settings ? DEFAULT.APP_NAME then "gitea (${cfg.settings.DEFAULT.APP_NAME})" else "gitea";
    infoFn = cfg: cfg.settings.server.ROOT_URL;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.settings.server.HTTP_ADDR}:${toString cfg.settings.server.HTTP_PORT}";
      };
    };
  };
  test = {
    config = {
      services.gitea = {
        enable = true;
        settings = {
          DEFAULT.APP_NAME = "My Gitea";
          server = {
            ROOT_URL = "https://gitea.example.com";
            HTTP_ADDR = "0.0.0.0";
            HTTP_PORT = 3000;
          };
        };
      };
    };
    expect = {
      name = "gitea (My Gitea)";
      info = "https://gitea.example.com";
      details.listen = "0.0.0.0:3000";
    };
  };
}
