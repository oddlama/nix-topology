_: {
  name = "Harmonia";
  icon = "services.not-available";
  nixos = {
    path = [
      "services"
      "harmonia"
    ];
    enabled = cfg: cfg.cache.enable or cfg.enable or false;
    detailsFn = _: { };
  };
  test = {
    config = {
      services.harmonia.enable = true;
    };
    assertions = services: [
      {
        assertion = services.harmonia.name == "Harmonia";
        message = "expected name 'Harmonia', got '${services.harmonia.name}'";
      }
    ];
  };
}
