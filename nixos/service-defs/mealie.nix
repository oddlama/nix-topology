_: {
  name = "Mealie";
  icon = "services.mealie";
  nixos = {
    path = [
      "services"
      "mealie"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.listenAddress}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.mealie = {
        enable = true;
        listenAddress = "127.0.0.1";
        port = 9000;
      };
    };
    assertions = services: [
      {
        assertion = services.mealie.name == "Mealie";
        message = "expected name 'Mealie', got '${services.mealie.name}'";
      }
      {
        assertion = services.mealie.details.listen.text == "127.0.0.1:9000";
        message = "expected listen '127.0.0.1:9000', got '${services.mealie.details.listen.text}'";
      }
    ];
  };
}
