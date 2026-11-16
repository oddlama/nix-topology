_: {
  name = "Harmonia";
  icon = "services.not-available";
  nixos = {
    path = "services.harmonia";
    # Also covers `services.harmonia-dev` from harmonia's flake module
    enabled = { cfg, config, ... }: config.services.harmonia-dev.cache.enable or cfg.cache.enable;
  };
  test = {
    minimalConfig = {
      services.harmonia.cache.enable = true;
    };
    # `services.harmonia-dev` must register as "harmonia", not separately
    config = { lib, ... }: {
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
