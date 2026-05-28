_: {
  name = "Mastodon";
  icon = "services.mastodon";
  nixos = {
    path = [
      "services"
      "mastodon"
    ];
    enabled = cfg: cfg.enable or false;
    infoFn = cfg: "https://${cfg.localDomain}";
    detailsFn = _: { };
  };
  test = {
    config = {
      services.mastodon = {
        enable = true;
        localDomain = "social.example.com";
        configureNginx = false;
        smtp.fromAddress = "noreply@example.com";
      };
    };
    assertions = services: [
      {
        assertion = services.mastodon.name == "Mastodon";
        message = "expected name 'Mastodon', got '${services.mastodon.name}'";
      }
      {
        assertion = services.mastodon.info == "https://social.example.com";
        message = "expected info 'https://social.example.com', got '${services.mastodon.info}'";
      }
    ];
  };
}
