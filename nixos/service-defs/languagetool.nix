_: {
  name = "Languagetool";
  icon = "services.languagetool";
  nixos = {
    path = [
      "services"
      "languagetool"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "127.0.0.1:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.languagetool = {
        enable = true;
        port = 8081;
      };
    };
    assertions = services: [
      {
        assertion = services.languagetool.name == "Languagetool";
        message = "expected name 'Languagetool', got '${services.languagetool.name}'";
      }
      {
        assertion = services.languagetool.details.listen.text == "127.0.0.1:8081";
        message = "expected listen '127.0.0.1:8081', got '${services.languagetool.details.listen.text}'";
      }
    ];
  };
}
