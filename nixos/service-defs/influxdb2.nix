_: {
  name = "InfluxDB v2";
  icon = "services.influxdb2";
  nixos = {
    path = [
      "services"
      "influxdb2"
    ];
    enabled = cfg: cfg.enable or false;
    detailsFn = cfg: {
      listen = {
        text = cfg.settings.http-bind-address or "localhost:8086";
      };
    };
  };
  test = {
    config = {
      services.influxdb2 = {
        enable = true;
        settings.http-bind-address = "0.0.0.0:8086";
      };
    };
    assertions = services: [
      {
        assertion = services.influxdb2.name == "InfluxDB v2";
        message = "expected name 'InfluxDB v2', got '${services.influxdb2.name}'";
      }
      {
        assertion = services.influxdb2.details.listen.text == "0.0.0.0:8086";
        message = "expected listen '0.0.0.0:8086', got '${services.influxdb2.details.listen.text}'";
      }
    ];
  };
}
