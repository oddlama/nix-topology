_: {
  name = "Meilisearch";
  icon = "services.meilisearch";
  nixos = {
    path = "services.meilisearch";
    detailsFn = cfg: {
      listen = {
        text = "${cfg.listenAddress}:${toString cfg.listenPort}";
      };
    };
  };
  test = {
    config = {
      services.meilisearch = {
        enable = true;
        listenAddress = "127.0.0.1";
        listenPort = 7700;
      };
    };
    expect = {
      name = "Meilisearch";
      details.listen = "127.0.0.1:7700";
    };
  };
}
