_: {
  name = "Kanidm";
  icon = "services.kanidm";
  nixos = {
    path = "services.kanidm";
    enabled = { cfg, ... }: cfg.server.enable;
    infoFn = { cfg, ... }: cfg.server.settings.origin;
    detailsFn = { cfg, ... }: {
      listen = {
        text = cfg.server.settings.bindaddress;
      };
    };
  };
  oci.repos = [ "kanidm/server" ];
  test = {
    minimalConfig = {
      services.kanidm.server = {
        enable = true;
        settings = {
          origin = "https://idm.example.com";
          domain = "example.com";
        };
      };
    };
    config = {
      services.kanidm.server = {
        enable = true;
        settings = {
          origin = "https://idm.example.com";
          bindaddress = "0.0.0.0:8443";
          domain = "example.com";
        };
      };
    };
    expect = {
      name = "Kanidm";
      info = "https://idm.example.com";
      details.listen = "0.0.0.0:8443";
    };
  };
}
