_: {
  name = "Seerr";
  icon = "services.seerr";
  nixos = {
    # Also covers `services.jellyseerr`, the only option before nixpkgs 26.05
    path = "services";
    enabled = cfg: (cfg.seerr or cfg.jellyseerr or { }).enable or false;
    detailsFn =
      cfg:
      let
        seerr = cfg.seerr or cfg.jellyseerr;
      in
      if seerr.openFirewall or false then
        {
          listen = {
            text = "0.0.0.0:${toString seerr.port}";
          };
        }
      else
        { };
  };
  test = {
    minimalConfig = {
      services.seerr.enable = true;
    };
    # Via the deprecated `jellyseerr` alias, which must not show up as a separate service
    config = {
      services.jellyseerr = {
        enable = true;
        openFirewall = true;
        port = 5055;
      };
    };
    expect = {
      name = "Seerr";
      details.listen = "0.0.0.0:5055";
    };
    assertions = services: [
      {
        assertion = !(services ? jellyseerr);
        message = "enabling the deprecated 'services.jellyseerr' alias must not also register a separate 'jellyseerr' entry (duplicate of 'seerr')";
      }
    ];
  };
}
