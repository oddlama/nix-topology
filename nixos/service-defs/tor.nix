_: {
  name = "Tor";
  icon = "services.tor";
  nixos = {
    path = "services.tor";
    infoFn = cfg: if cfg.relay.enable or false then "Role: ${cfg.relay.role}" else null;
    detailsFn = _: { };
  };
  test = {
    config = {
      services.tor = {
        enable = true;
        relay = {
          enable = true;
          role = "relay";
        };
      };
    };
    expect = {
      name = "Tor";
      info = "Role: relay";
    };
  };
}
