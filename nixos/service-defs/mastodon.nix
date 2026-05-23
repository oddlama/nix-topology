_: {
  name = "Mastodon";
  icon = "services.mastodon";
  nixos = {
    path = "services.mastodon";
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
    expect = {
      name = "Mastodon";
      info = "https://social.example.com";
    };
  };
}
