_: {
  name = "Languagetool";
  icon = "services.languagetool";
  nixos = {
    path = "services.languagetool";
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
    expect = {
      name = "Languagetool";
      details.listen = "127.0.0.1:8081";
    };
  };
}
