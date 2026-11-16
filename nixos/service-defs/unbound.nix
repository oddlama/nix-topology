_: {
  name = "Unbound";
  icon = "services.unbound";
  nixos = {
    path = "services.unbound";
    detailsFn =
      { cfg, ... }:
      let
        port = toString (cfg.settings.server.port or 53);
      in
      {
        listen = {
          text = toString (map (interface: "${interface}:${port}") cfg.settings.server.interface);
        };
      };
  };
  test = {
    config = {
      services.unbound = {
        enable = true;
        settings.server = {
          interface = [
            "0.0.0.0"
            "::"
          ];
          port = 5335;
        };
      };
    };
    expect = {
      name = "Unbound";
      details.listen = "0.0.0.0:5335 :::5335";
    };
  };
}
