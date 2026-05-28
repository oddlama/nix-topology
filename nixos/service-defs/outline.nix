_: {
  name = "Outline";
  icon = "services.outline";
  nixos = {
    path = [
      "services"
      "outline"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.publicUrl}";
      };
    };
  };
  test = {
    config = {
      services.outline = {
        enable = true;
        publicUrl = "https://outline.example.com";
        secretKeyFile = "/dev/null";
        utilsSecretFile = "/dev/null";
        storage.storageType = "local";
      };
    };
    assertions = services: [
      {
        assertion = services.outline.name == "Outline";
        message = "expected name 'Outline', got '${services.outline.name}'";
      }
      {
        assertion = services.outline.details.listen.text == "https://outline.example.com";
        message = "expected listen 'https://outline.example.com', got '${services.outline.details.listen.text}'";
      }
    ];
  };
}
