_: {
  name = "OAuth2 Proxy";
  icon = "services.oauth2-proxy";
  nixos = {
    path = "services.oauth2-proxy";
    infoFn = { cfg, ... }: cfg.httpAddress;
  };
  oci.repos = [ "oauth2-proxy" ];
  test = {
    config = {
      services.oauth2-proxy = {
        enable = true;
        httpAddress = "http://127.0.0.1:4180";
      };
    };
    expect = {
      name = "OAuth2 Proxy";
    };
  };
}
