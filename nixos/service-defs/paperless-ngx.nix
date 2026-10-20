_: {
  name = "Paperless-ngx";
  icon = "services.paperless-ngx";
  nixos = {
    path = "services.paperless";
    infoFn =
      cfg:
      let
        domain = cfg.domain or null;
      in
      if domain != null then "https://${domain}" else null;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.address}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.paperless = {
        enable = true;
        address = "0.0.0.0";
        port = 8000;
        domain = "paperless.example.com";
      };
    };
    expect = {
      name = "Paperless-ngx";
      info = "https://paperless.example.com";
      details.listen = "0.0.0.0:8000";
    };
  };
}
