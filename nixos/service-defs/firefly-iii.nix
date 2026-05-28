_: {
  name = "Firefly III";
  icon = "services.firefly-iii";
  nixos = {
    path = [
      "services"
      "firefly-iii"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: cfg.settings.APP_URL or null;
  };
  test = {
    config = {
      services.firefly-iii = {
        enable = true;
        settings.APP_URL = "https://firefly.example.com";
      };
    };
    assertions = services: [
      {
        assertion = services.firefly-iii.name == "Firefly III";
        message = "expected name 'Firefly III', got '${services.firefly-iii.name}'";
      }
      {
        assertion = services.firefly-iii.info == "https://firefly.example.com";
        message = "expected info 'https://firefly.example.com', got '${services.firefly-iii.info}'";
      }
    ];
  };
}
