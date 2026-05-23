_: {
  name = "MPD";
  icon = "services.mpd";
  nixos = {
    path = [
      "services"
      "mpd"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn =
      cfg:
      let
        addr =
          if cfg ? settings then
            if cfg.settings.bind_to_address == "any" then "0.0.0.0" else cfg.settings.bind_to_address
          else
            cfg.network.listenAddress;
        port = if cfg ? settings then cfg.settings.port else cfg.network.port;
      in
      {
        listen.text = "${addr}:${toString port}";
      };
  };
  test = {
    config = {
      services.mpd = {
        enable = true;
      };
    };
    assertions = services: [
      {
        assertion = services.mpd.name == "MPD";
        message = "expected name 'MPD', got '${services.mpd.name}'";
      }
    ];
  };
}
