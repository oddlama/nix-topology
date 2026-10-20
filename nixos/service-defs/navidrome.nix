_: {
  name = "Navidrome";
  icon = "services.navidrome";
  nixos = {
    path = "services.navidrome";
    infoFn = cfg: cfg.settings.BaseUrl or null;
    detailsFn =
      cfg:
      if cfg.openFirewall then
        {
          listen = {
            text = "${cfg.settings.Address}:${toString cfg.settings.Port}";
          };
        }
      else
        { };
  };
  test = {
    config = {
      services.navidrome = {
        enable = true;
        openFirewall = true;
        settings = {
          BaseUrl = "https://music.example.com";
          Address = "0.0.0.0";
          Port = 4533;
        };
      };
    };
    expect = {
      name = "Navidrome";
      info = "https://music.example.com";
      details.listen = "0.0.0.0:4533";
    };
  };
}
