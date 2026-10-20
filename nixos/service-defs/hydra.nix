_: {
  name = "Hydra";
  icon = "devices.nixos";
  nixos = {
    path = "services.hydra";
    infoFn = cfg: cfg.hydraURL;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.listenHost}:${toString cfg.port}";
      };
    };
  };
  test = {
    minimalConfig = {
      services.hydra = {
        enable = true;
        hydraURL = "https://hydra.example.com";
        notificationSender = "hydra@example.com";
      };
    };
    config = {
      services.hydra = {
        enable = true;
        hydraURL = "https://hydra.example.com";
        notificationSender = "hydra@example.com";
        listenHost = "127.0.0.1";
        port = 3000;
      };
    };
    expect = {
      name = "Hydra";
      info = "https://hydra.example.com";
      details.listen = "127.0.0.1:3000";
    };
  };
}
