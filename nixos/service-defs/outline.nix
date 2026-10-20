_: {
  name = "Outline";
  icon = "services.outline";
  nixos = {
    path = "services.outline";
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
    expect = {
      name = "Outline";
      details.listen = "https://outline.example.com";
    };
  };
}
