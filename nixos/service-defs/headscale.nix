_: {
  name = "Headscale";
  icon = "services.headscale";
  nixos = {
    path = [
      "services"
      "headscale"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: cfg.settings.server_url;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.address}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.headscale = {
        enable = true;
        address = "0.0.0.0";
        port = 8080;
        settings.server_url = "https://headscale.example.com";
      };
    };
    assertions = services: [
      {
        assertion = services.headscale.name == "Headscale";
        message = "expected name 'Headscale', got '${services.headscale.name}'";
      }
      {
        assertion = services.headscale.info == "https://headscale.example.com";
        message = "expected info 'https://headscale.example.com', got '${services.headscale.info}'";
      }
      {
        assertion = services.headscale.details.listen.text == "0.0.0.0:8080";
        message = "expected listen '0.0.0.0:8080', got '${services.headscale.details.listen.text}'";
      }
    ];
  };
}
