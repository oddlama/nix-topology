_: {
  name = "Static Web Server";
  icon = "devices.nixos";
  nixos = {
    path = "services.static-web-server";
    detailsFn = cfg: {
      listen = {
        text = toString cfg.listen;
      };
      root = {
        text = toString cfg.root;
      };
    };
  };
  test = {
    config = {
      services.static-web-server = {
        enable = true;
        listen = "0.0.0.0:8787";
        root = "/var/www";
      };
    };
    expect = {
      name = "Static Web Server";
      details.listen = "0.0.0.0:8787";
      details.root = "/var/www";
    };
  };
}
