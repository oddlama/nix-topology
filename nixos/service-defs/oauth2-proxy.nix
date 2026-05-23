_: {
  name = "OAuth2 Proxy";
  icon = "services.oauth2-proxy";
  nixos = {
    path = [
      "services"
      "oauth2-proxy"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: cfg.httpAddress;
    detailsFn = _: { };
  };
  test = {
    config = {
      services.oauth2-proxy = {
        enable = true;
        httpAddress = "http://127.0.0.1:4180";
      };
    };
    assertions = services: [
      {
        assertion = services."oauth2-proxy".name == "OAuth2 Proxy";
        message = "expected name 'OAuth2 Proxy', got '${services."oauth2-proxy".name}'";
      }
    ];
  };
}
