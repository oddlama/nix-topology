_: {
  name = "Kanidm";
  icon = "services.kanidm";
  nixos = {
    path = "services.kanidm";
    enabled = cfg: cfg.server.enable or cfg.enableServer or false;
    infoFn = cfg: cfg.server.settings.origin or cfg.serverSettings.origin;
    detailsFn = cfg: {
      listen = {
        text = cfg.server.settings.bindaddress or cfg.serverSettings.bindaddress;
      };
    };
  };
  test = {
    config = {
      services.kanidm = {
        enableServer = true;
        serverSettings = {
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
