_: {
  name = "Alloy";
  icon = "services.alloy";
  nixos = {
    path = [
      "services"
      "alloy"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = _: { };
  };
  test = {
    config = {
      services.alloy = {
        enable = true;
      };
    };
    assertions = services: [
      {
        assertion = services.alloy.name == "Alloy";
        message = "expected name 'Alloy', got '${services.alloy.name}'";
      }
    ];
  };
}
