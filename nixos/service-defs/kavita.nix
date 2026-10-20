_: {
  name = "Kavita";
  icon = "services.kavita";
  nixos = {
    path = "services.kavita";
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
    expect = {
      name = "Kavita";
      details.listen = "0.0.0.0:5000";
    };
  };
}
