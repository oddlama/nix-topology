_: {
  name = "Meilisearch";
  icon = "services.meilisearch";
  nixos = {
    path = [
      "services"
      "meilisearch"
    ];
    enabled = cfg: cfg.enable or false;
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
    assertions = services: [
      {
        assertion = services.meilisearch.name == "Meilisearch";
        message = "expected name 'Meilisearch', got '${services.meilisearch.name}'";
      }
      {
        assertion = services.meilisearch.details.listen.text == "127.0.0.1:7700";
        message = "expected listen '127.0.0.1:7700', got '${services.meilisearch.details.listen.text}'";
      }
    ];
  };
}
