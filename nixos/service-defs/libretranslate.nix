_: {
  name = "Libretranslate";
  icon = "services.libretranslate";
  nixos = {
    path = [
      "services"
      "libretranslate"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.host}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.libretranslate = {
        enable = true;
        host = "0.0.0.0";
        port = 5000;
      };
    };
    assertions = services: [
      {
        assertion = services.libretranslate.name == "Libretranslate";
        message = "expected name 'Libretranslate', got '${services.libretranslate.name}'";
      }
      {
        assertion = services.libretranslate.details.listen.text == "0.0.0.0:5000";
        message = "expected listen '0.0.0.0:5000', got '${services.libretranslate.details.listen.text}'";
      }
    ];
  };
}
