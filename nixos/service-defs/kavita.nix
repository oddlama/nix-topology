_: {
  name = "Kavita";
  icon = "services.kavita";
  nixos = {
    path = [
      "services"
      "kavita"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "0.0.0.0:${toString cfg.settings.Port}";
      };
    };
  };
  test = {
    config = {
      services.kavita = {
        enable = true;
        tokenKeyFile = "/dev/null";
        settings.Port = 5000;
      };
    };
    assertions = services: [
      {
        assertion = services.kavita.name == "Kavita";
        message = "expected name 'Kavita', got '${services.kavita.name}'";
      }
      {
        assertion = services.kavita.details.listen.text == "0.0.0.0:5000";
        message = "expected listen '0.0.0.0:5000', got '${services.kavita.details.listen.text}'";
      }
    ];
  };
}
