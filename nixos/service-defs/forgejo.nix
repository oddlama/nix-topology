_: {
  name = "Forgejo";
  icon = "services.forgejo";
  nixos = {
    path = [
      "services"
      "forgejo"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.forgejo.name == "Forgejo (My Forge)";
        message = "expected name 'Forgejo (My Forge)', got '${services.forgejo.name}'";
      }
      {
        assertion = services.forgejo.info == "https://forgejo.example.com";
        message = "expected info 'https://forgejo.example.com', got '${services.forgejo.info}'";
      }
      {
        assertion = services.forgejo.details.listen.text == "127.0.0.1:3000";
        message = "expected listen '127.0.0.1:3000', got '${services.forgejo.details.listen.text}'";
      }
    ];
  };
}
