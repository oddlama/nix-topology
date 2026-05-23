_: {
  name = "Prometheus";
  icon = "services.prometheus";
  nixos = {
    path = [
      "services"
      "prometheus"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = "${cfg.listenAddress}:${toString cfg.port}";
      };
    };
  };
  test = {
    config = {
      services.prometheus = {
        enable = true;
        listenAddress = "0.0.0.0";
        port = 9090;
      };
    };
    assertions = services: [
      {
        assertion = services.prometheus.name == "Prometheus";
        message = "expected name 'Prometheus', got '${services.prometheus.name}'";
      }
      {
        assertion = services.prometheus.details.listen.text == "0.0.0.0:9090";
        message = "expected listen '0.0.0.0:9090', got '${services.prometheus.details.listen.text}'";
      }
    ];
  };
}
