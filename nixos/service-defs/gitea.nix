_: {
  name = "gitea";
  icon = "services.gitea";
  nixos = {
    path = [
      "services"
      "gitea"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.gitea.name == "gitea (My Gitea)";
        message = "expected name 'gitea (My Gitea)', got '${services.gitea.name}'";
      }
      {
        assertion = services.gitea.info == "https://gitea.example.com";
        message = "expected info 'https://gitea.example.com', got '${services.gitea.info}'";
      }
      {
        assertion = services.gitea.details.listen.text == "0.0.0.0:3000";
        message = "expected listen '0.0.0.0:3000', got '${services.gitea.details.listen.text}'";
      }
    ];
  };
}
