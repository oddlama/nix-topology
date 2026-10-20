_: {
  name = "Harmonia";
  icon = "services.not-available";
  nixos = {
    # Also covers `services.harmonia-dev` from harmonia's flake module
    path = "services";
    enabled =
      cfg: cfg.harmonia-dev.cache.enable or cfg.harmonia.cache.enable or cfg.harmonia.enable or false;
    detailsFn = _: { };
  };
  test = {
    minimalConfig = {
      services.harmonia.enable = true;
    };
    # `services.harmonia-dev` must register as "harmonia", not separately
    config =
      { lib, ... }:
      {
        # Declared by harmonia's flake module
        options.services.harmonia-dev.cache.enable = lib.mkEnableOption "harmonia-dev";
        config.services.harmonia-dev.cache.enable = true;
      };
    expect = {
      name = "Harmonia";
    };
    assertions = services: [
      {
        assertion = !(services ? harmonia-dev);
        message = "expected no separate 'harmonia-dev' service";
      }
    ];
  };
}
