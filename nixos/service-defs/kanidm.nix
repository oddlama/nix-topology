_: {
  name = "Kanidm";
  icon = "services.kanidm";
  nixos = {
    path = [
      "services"
      "kanidm"
    ];
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
    assertions = services: [
      {
        assertion = services.kanidm.name == "Kanidm";
        message = "expected name 'Kanidm', got '${services.kanidm.name}'";
      }
      {
        assertion = services.kanidm.info == "https://idm.example.com";
        message = "expected info 'https://idm.example.com', got '${services.kanidm.info}'";
      }
      {
        assertion = services.kanidm.details.listen.text == "0.0.0.0:8443";
        message = "expected listen '0.0.0.0:8443', got '${services.kanidm.details.listen.text}'";
      }
    ];
  };
}
