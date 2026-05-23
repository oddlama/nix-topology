_: {
  name = "Nix Serve";
  icon = "devices.nixos";
  nixos = {
    path = [
      "services"
      "nix-serve"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.bindAddress}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.nix-serve = {
        enable = true;
        bindAddress = "0.0.0.0";
        port = 5000;
      };
    };
    assertions = services: [
      {
        assertion = services.nix-serve.name == "Nix Serve";
        message = "expected name 'Nix Serve', got '${services.nix-serve.name}'";
      }
      {
        assertion = services.nix-serve.details.listen.text == "0.0.0.0:5000";
        message = "expected listen '0.0.0.0:5000', got '${services.nix-serve.details.listen.text}'";
      }
    ];
  };
}
