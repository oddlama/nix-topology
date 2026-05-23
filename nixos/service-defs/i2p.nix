_: {
  name = "I2P";
  icon = "services.i2p";
  nixos = {
    path = [
      "services"
      "i2pd"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = _: { };
  };
  test = {
    config = {
      services.i2pd = {
        enable = true;
      };
    };
    assertions = services: [
      {
        assertion = services.i2p.name == "I2P";
        message = "expected name 'I2P', got '${services.i2p.name}'";
      }
    ];
  };
}
