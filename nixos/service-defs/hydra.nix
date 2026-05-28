_: {
  name = "Hydra";
  icon = "devices.nixos";
  nixos = {
    path = [
      "services"
      "hydra"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: cfg.hydraURL;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.listenHost}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.hydra = {
        enable = true;
        hydraURL = "https://hydra.example.com";
        notificationSender = "hydra@example.com";
        listenHost = "127.0.0.1";
        port = 3000;
      };
    };
    assertions = services: [
      {
        assertion = services.hydra.name == "Hydra";
        message = "expected name 'Hydra', got '${services.hydra.name}'";
      }
      {
        assertion = services.hydra.info == "https://hydra.example.com";
        message = "expected info 'https://hydra.example.com', got '${services.hydra.info}'";
      }
      {
        assertion = services.hydra.details.listen.text == "127.0.0.1:3000";
        message = "expected listen '127.0.0.1:3000', got '${services.hydra.details.listen.text}'";
      }
    ];
  };
}
