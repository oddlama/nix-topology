_: {
  name = "Harmonia";
  icon = "services.not-available";
  nixos = {
    path = [
      "services"
      "harmonia-dev"
    ];
    enabled = cfg: cfg.cache.enable or false;
    detailsFn = _: { };
  };
}
