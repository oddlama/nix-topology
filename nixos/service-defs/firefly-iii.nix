_: {
  name = "Firefly III";
  icon = "services.firefly-iii";
  nixos = {
    path = "services.firefly-iii";
    infoFn = cfg: cfg.settings.APP_URL or null;
  };
  test = {
    config = {
      services.firefly-iii = {
        enable = true;
        settings.APP_URL = "https://firefly.example.com";
      };
    };
    expect = {
      name = "Firefly III";
      info = "https://firefly.example.com";
    };
  };
}
