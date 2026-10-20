_: {
  name = "Nix Serve";
  icon = "devices.nixos";
  nixos = {
    path = "services.nix-serve";
    detailsFn = cfg: {
      listen = {
        text = "${cfg.bindAddress}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.nix-serve = {
        enable = true;
        bindAddress = "0.0.0.0";
        port = 5000;
      };
    };
    expect = {
      name = "Nix Serve";
      details.listen = "0.0.0.0:5000";
    };
  };
}
