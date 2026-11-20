_: {
  name = "Gitea Actions Runner";
  icon = "services.gitea";
  nixos = {
    path = "services.gitea-actions-runner.instances";
    instances = true;
    nameFn = { instance, ... }: "Gitea Actions Runner '${instance}'";
    infoFn = { cfg, ... }: cfg.url;
  };
  test = {
    instance = "home";
    config = {
      services.gitea-actions-runner.instances = {
        home = {
          enable = true;
          name = "home";
          url = "https://git.example.com";
          tokenFile = "/run/secrets/gitea-runner";
          labels = [ "native:host" ];
        };
        # Only enabled instances appear
        off = {
          name = "off";
          url = "https://git.example.com";
          tokenFile = "/run/secrets/gitea-runner";
          labels = [ "native:host" ];
        };
      };
    };
    expect = {
      name = "Gitea Actions Runner 'home'";
      info = "https://git.example.com";
    };
    assertions = services: [
      {
        assertion = !(services ? gitea-actions-runner-off);
        message = "expected the disabled instance 'off' not to appear, got: ${toString (builtins.attrNames services)}";
      }
    ];
  };
}
